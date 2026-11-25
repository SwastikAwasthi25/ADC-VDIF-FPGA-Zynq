#!/usr/bin/env python3
"""CAL9 ABI-3 engineering recorder. Default: offline selftest. No FPGA programming.
Physical operation requires independent board qualification and explicit permissions.
"""
from __future__ import annotations
import argparse
import ctypes
import hashlib
import json
import os
from pathlib import Path
import struct
import sys
import tempfile
import time
import unittest

BRAM_BASE = 0x40000000
AXIL_BASE = 0x40010000
BRAM_WINDOW = 0x2000
REG_WINDOW = 0x1000
BANK_STRIDE = 0x800
FRAME_BYTES = 1056
PAYLOAD_BYTES = 1024
# Active BD wrapper v4_ps_axil_epoch_bd_ref.v -> v4_ps_axil_control_epoch.sv
# These identity values are source-proven, NOT proof of which FPGA image runs.
MAGIC = 0x56344332  # V4C2
VERSION = 0x00010003
ACTIVE_EPOCH_CONTRACT_RECONCILED = True
R = {"magic":0x000,"version":0x004,"state":0x008,"command":0x00c,
     "ack_seq":0x010,"ack_bank":0x014,"ready":0x018,"bank0_seq":0x01c,
     "bank1_seq":0x020,"completed":0x024,"last_ack":0x028,"err_count":0x02c,
     "events":0x030,"avail":0x034,"epoch":0x038,"ack_epoch":0x040,"cal_status":0x048,
     "period":0x04c,"capture_cmd":0x050,"capture_status":0x054,
     "active_period":0x058,"started":0x05c,"replayed":0x060,"skipped":0x064}
STATUS_BUSY = 0x01
ACK_BUSY = 0x02
STATUS_DONE = 0x04
ACK_DONE = 0x08
ACK_ACCEPTED = 0x10
CMD_ERROR = 0x20

class GuardError(Exception):
    pass


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def frame_check(data: bytes) -> dict:
    if len(data) != FRAME_BYTES:
        raise GuardError(f"VDIF length {len(data)} is not {FRAME_BYTES}")
    words = struct.unpack('<8I', data[:32])
    declared = (words[2] & 0x00FFFFFF) * 8
    if declared != FRAME_BYTES:
        raise GuardError(f"VDIF header frame length {declared}, expected {FRAME_BYTES}")
    # Structural checks are not evidence that the physical ADC produced valid samples.
    return {"frame_bytes": len(data), "header_words": [f"0x{x:08X}" for x in words],
            "declared_frame_bytes": declared, "payload_bytes":len(data[32:]),
            "payload_sha256":sha(data[32:]), "payload_all_zero":not any(data[32:]),
            "invalid_flag":bool(words[0] & 0x80000000),
            "thread_id":(words[3] >> 16) & 0x3ff,
            "frame_sha256": sha(data)}


class LinuxMMIO:
    """Linux-only, aligned volatile-style 32-bit MMIO via libc mmap + ctypes.

    AXI-Lite RTL accepts only WSTRB=0xF. NEVER use mmap byte-slice
    assignment to write a register: Python's memcpy may emit subword writes.
    This backend is inert until explicitly instantiated after board signoff.
    """
    _PROT_READ = 1
    _PROT_WRITE = 2
    _MAP_SHARED = 1
    _MAP_FAILED = ctypes.c_void_p(-1).value

    def __init__(self, writable: bool):
        if os.name != 'posix' or not Path('/dev/mem').exists():
            raise GuardError('Hardware mode only on intended Linux board with /dev/mem')
        if ctypes.sizeof(ctypes.c_uint32) != 4:
            raise GuardError('host has non-32-bit c_uint32')
        self.writable = writable
        self.fd = None
        self.ctrl_ptr = None
        self.bram_ptr = None
        self.libc = ctypes.CDLL(None, use_errno=True)
        self.libc.mmap.argtypes = [ctypes.c_void_p, ctypes.c_size_t, ctypes.c_int,
                                  ctypes.c_int, ctypes.c_int, ctypes.c_long]
        self.libc.mmap.restype = ctypes.c_void_p
        self.libc.munmap.argtypes = [ctypes.c_void_p, ctypes.c_size_t]
        self.libc.munmap.restype = ctypes.c_int
        flags = (os.O_RDWR if writable else os.O_RDONLY) | getattr(os, 'O_SYNC', 0)
        try:
            self.fd = os.open('/dev/mem', flags)
            self.ctrl_ptr = self._map(AXIL_BASE, REG_WINDOW,
                self._PROT_READ | (self._PROT_WRITE if writable else 0))
            if writable:  # capture mode only; probe touches control aperture alone
                self.bram_ptr = self._map(BRAM_BASE, BRAM_WINDOW, self._PROT_READ)
        except Exception:
            self.close()
            raise

    def _map(self, address: int, size: int, prot: int) -> int:
        ptr = self.libc.mmap(None, size, prot, self._MAP_SHARED, self.fd, address)
        if ptr == self._MAP_FAILED or ptr is None:
            err = ctypes.get_errno()
            raise OSError(err, f'physical MMIO map failed 0x{address:08X} ({size} bytes)')
        return int(ptr)

    def read(self, off: int) -> int:
        if off not in (*R.values(), 0x048) or off % 4:
            raise GuardError(f'unknown or unaligned register 0x{off:x}')
        return ctypes.c_uint32.from_address(self.ctrl_ptr + off).value

    def write(self, off: int, value: int) -> None:
        if not self.writable:
            raise GuardError('MMIO writes disabled')
        if off not in (R['command'], R['events'], R['ack_seq'], R['ack_bank'], R['ack_epoch'], R['period'], R['capture_cmd']):
            raise GuardError(f'write to unapproved offset 0x{off:x}')
        if not 0 <= value <= 0xffffffff or off % 4:
            raise GuardError('unaligned/overflow AXI-Lite write')
        # c_uint32 word assignment requests a single aligned 32-bit access.
        # Validate AXI4-Lite WSTRB=0xF on the deployed bus for sign-off.
        ctypes.c_uint32.from_address(self.ctrl_ptr + off).value = value
        # Read back command/config state in following control protocol calls.

    def frame(self, bank: int) -> bytes:
        if bank not in (0, 1):
            raise GuardError('invalid BRAM bank')
        if self.bram_ptr is None:
            raise GuardError('BRAM access disabled in read-only register probe')
        off = bank * BANK_STRIDE
        return ctypes.string_at(self.bram_ptr + off, FRAME_BYTES)

    def close(self):
        if getattr(self, 'bram_ptr', None) is not None:
            self.libc.munmap(ctypes.c_void_p(self.bram_ptr), BRAM_WINDOW)
            self.bram_ptr = None
        if getattr(self, 'ctrl_ptr', None) is not None:
            self.libc.munmap(ctypes.c_void_p(self.ctrl_ptr), REG_WINDOW)
            self.ctrl_ptr = None
        if getattr(self, 'fd', None) is not None:
            os.close(self.fd)
            self.fd = None

    def __enter__(self): return self
    def __exit__(self, *args): self.close()


def check_identity(hw, expected_version=VERSION):
    magic,version = hw.read(R['magic']), hw.read(R['version'])
    if magic != MAGIC or version != expected_version:
        raise GuardError(f'bitstream register identity mismatch: MAGIC=0x{magic:08X} '
                         f'VERSION=0x{version:08X}, expected 0x{MAGIC:08X}/0x{expected_version:08X}')
    return {'magic':f'0x{magic:08X}', 'version':f'0x{version:08X}'}


def check_live_epoch(hw, expected=None):
    """Fail closed on frontend reset/offline or unstable PS-visible epoch.

    Epoch is a *software guard*; it does not establish physical calibration or
    the installed bitstream's exact routed provenance.
    """
    a0 = hw.read(R['avail'])
    e0 = hw.read(R['epoch'])
    a1 = hw.read(R['avail'])
    e1 = hw.read(R['epoch'])
    if (a0, a1) != (1, 1) or e0 != e1:
        raise GuardError(f'frontend offline or unstable epoch: avail={a0},{a1} epoch={e0},{e1}; NO ACK')
    if expected is not None and e1 != expected:
        raise GuardError(f'frontend epoch changed: expected={expected} now={e1}; NO ACK')
    return e1


def register_snapshot(hw):
    result = {name:hw.read(off) for name,off in R.items() if name not in ('command','capture_cmd')}
    return result


def wait_for(hw, complete_mask: int, busy_mask: int, deadline: float, epoch: int):
    while time.monotonic() < deadline:
        check_live_epoch(hw, epoch)
        state = hw.read(R['state'])
        if state & CMD_ERROR:
            raise GuardError(f'control register error, state=0x{state:08X}; NO ACK')
        if (state & complete_mask) and not (state & busy_mask):
            check_live_epoch(hw, epoch)
            return state
        time.sleep(0.0002)
    raise GuardError('mailbox timeout; NO ACK')


def status(hw, timeout:float=2.0):
    epoch = check_live_epoch(hw)
    state = hw.read(R['state'])
    if state & (STATUS_BUSY|ACK_BUSY|CMD_ERROR):
        raise GuardError(f'previous mailbox transaction busy or error, state=0x{state:08X}')
    errors = hw.read(R['err_count'])
    hw.write(R['events'], 1)  # W1C old status_done, not ACK
    check_live_epoch(hw, epoch)
    if hw.read(R['state']) & STATUS_DONE:
        raise GuardError('status_done sticky failed to clear; stale snapshot prohibited')
    hw.write(R['command'], 1)
    state = wait_for(hw, STATUS_DONE, STATUS_BUSY, time.monotonic()+timeout, epoch)
    if hw.read(R['err_count']) != errors or state & CMD_ERROR:
        raise GuardError('status command reported register error')
    ready = hw.read(R['ready'])
    if ready & ~3:
        raise GuardError('unexpected READY bits')
    snapshot = {'ready':ready, 'bank0_seq':hw.read(R['bank0_seq']),
                'bank1_seq':hw.read(R['bank1_seq']),
                'completed':hw.read(R['completed']), 'state':state, 'epoch':epoch}
    snapshot.update({k:hw.read(R[k]) for k in ('active_period','started','replayed','skipped','capture_status')})
    check_live_epoch(hw, epoch)
    return snapshot


def choose_bank(st:dict) -> tuple[int,int] | None:
    ready = st['ready']
    if not ready:
        return None
    if ready == 1:
        return (0,st['bank0_seq'])
    if ready == 2:
        return (1,st['bank1_seq'])
    a,b = st['bank0_seq'],st['bank1_seq']
    delta = (a-b) & 0xffffffff
    if delta == 0 or delta == 0x80000000:
        raise GuardError('ambiguous bank sequence ordering')
    return (1,b) if delta < 0x80000000 else (0,a)


def same_bank(st: dict, bank:int, seq:int) -> bool:
    return bool(st['ready'] & (1<<bank)) and st[f'bank{bank}_seq'] == seq


def durable_write(path:Path, data:bytes):
    if path.exists():
        raise GuardError(f'output already exists: {path}')
    with path.open('xb') as f:
        f.write(data)
        f.flush()
        os.fsync(f.fileno())
    if path.read_bytes() != data:
        raise GuardError('disk readback mismatch (NO ACK)')


def durable_manifest(path:Path, data:dict):
    encoded=(json.dumps(data, indent=2,sort_keys=True)+'\n').encode('utf-8')
    durable_write(path,encoded)
    if path.read_bytes() != encoded:
        raise GuardError('manifest readback mismatch (NO ACK)')
    # On Linux fsync directory entry; failure is fatal before any hardware ACK.
    if os.name == 'posix':
        fd=os.open(str(path.parent),os.O_RDONLY|getattr(os,'O_DIRECTORY',0))
        try: os.fsync(fd)
        finally: os.close(fd)


def ack(hw, bank:int,seq:int,epoch:int,timeout:float=2.0):
    # Recheck the actual published frame immediately before any ACK.
    check_live_epoch(hw, epoch)
    fresh = status(hw, timeout)
    if fresh['epoch'] != epoch or not same_bank(fresh, bank, seq):
        raise GuardError('frame bank/sequence/epoch no longer matches; NO ACK')
    state=hw.read(R['state'])
    if state & (STATUS_BUSY|ACK_BUSY|CMD_ERROR):
        raise GuardError('mailbox busy or in error; cannot ACK')
    errors=hw.read(R['err_count'])
    hw.write(R['events'], 2)
    check_live_epoch(hw, epoch)
    if hw.read(R['state']) & ACK_DONE:
        raise GuardError('ack_done sticky did not clear')
    # This epoch-aware core explicitly requires all three config writes.
    hw.write(R['ack_seq'],seq)
    hw.write(R['ack_bank'],bank)
    hw.write(R['ack_epoch'],epoch)
    if (hw.read(R['ack_seq'])!=seq or hw.read(R['ack_bank'])!=bank
            or hw.read(R['ack_epoch'])!=epoch):
        raise GuardError('ACK seq/bank/epoch configuration readback mismatch; NO ACK')
    check_live_epoch(hw, epoch)
    hw.write(R['command'],2)
    state=wait_for(hw,ACK_DONE,ACK_BUSY,time.monotonic()+timeout,epoch)
    if hw.read(R['err_count'])!=errors or state & CMD_ERROR:
        raise GuardError('ACK command register error')
    if not (state & ACK_ACCEPTED) or hw.read(R['last_ack'])!=1:
        raise GuardError('ACK rejected by sequence/epoch-qualified mailbox')
    check_live_epoch(hw, epoch)


CAP_BUSY, CAP_DONE, CAP_ACCEPTED, CAP_RUN, CAP_IDLE = 1,2,4,8,16
MASK = 0xffffffff

def live(hw, epoch=None):
    e = check_live_epoch(hw, epoch)
    if hw.read(R['cal_status']) & 31 != 0x1d:
        raise GuardError('calibration status not normal/online')
    return e

def snap(hw, epoch):
    live(hw, epoch)
    st = status(hw)
    if st['epoch'] != epoch:
        raise GuardError('snapshot epoch changed')
    live(hw, epoch)
    return st

def control(hw, epoch, cmd, timeout=2.0):
    check_live_epoch(hw, epoch)
    if cmd == 1: live(hw, epoch)
    if hw.read(R['state']) & (STATUS_BUSY|ACK_BUSY|CMD_ERROR) or hw.read(R['capture_status']) & CAP_BUSY:
        raise GuardError('control mailbox busy/error')
    errors = hw.read(R['err_count'])
    hw.write(R['capture_cmd'], cmd)
    # ABI-3 clears done/accepted when a new command is issued.
    deadline = time.monotonic()+timeout
    while time.monotonic() < deadline:
        check_live_epoch(hw, epoch)
        if hw.read(R['err_count']) != errors or hw.read(R['state']) & CMD_ERROR:
            raise GuardError('capture command register error')
        c = hw.read(R['capture_status'])
        if not c & CAP_BUSY and c & CAP_DONE:
            if not c & CAP_ACCEPTED: raise GuardError('capture command rejected')
            check_live_epoch(hw, epoch)
            return
        time.sleep(.0002)
    raise GuardError('capture command timeout; hardware state uncertain')

def drained(st):
    return (not st['ready'] and not st['capture_status'] & CAP_RUN
            and bool(st['capture_status'] & CAP_IDLE)
            and st['started']==st['replayed']==st['completed'])

def sync_dir(path):
    if os.name=='posix':
        fd=os.open(str(path),os.O_RDONLY|getattr(os,'O_DIRECTORY',0))
        try: os.fsync(fd)
        finally: os.close(fd)

def record(hw, outdir, seconds=300, period=125000000, drain_timeout=10.0,
           progress_timeout=5.0, clock=time.monotonic, sleep=time.sleep):
    if not 0 < seconds <= 300 or not 12500 <= period <= 125000000:
        raise GuardError('duration/period outside bounds')
    if not 1 <= drain_timeout <= 60 or not 2 <= progress_timeout <= 60:
        raise GuardError('timeout outside bounds')
    identity=check_identity(hw)
    epoch=live(hw)
    base=snap(hw,epoch)
    if not drained(base): raise GuardError('pre-existing run or undrained banks; no START')
    outdir=Path(outdir).resolve()
    if not outdir.is_dir(): raise GuardError('output directory must exist')
    data=outdir/'ch0_cal9.vdif'; journal=outdir/'ch0_cal9.jsonl'; final=outdir/'ch0_cal9_summary.json'
    if any(p.exists() for p in (data,journal,final)): raise GuardError('output exists; no overwrite')
    count=0; pending=None; armed=False; stopped=False; digest=hashlib.sha256()
    def event(j, obj):
        j.write((json.dumps(obj,sort_keys=True)+'\n').encode()); j.flush(); os.fsync(j.fileno())
    with data.open('xb') as f, journal.open('xb') as j:
        event(j,{'event':'preflight','identity':identity,'epoch':epoch,'baseline':base,'period_cycles':period,'requested_seconds':seconds})
        sync_dir(outdir)
        try:
            live(hw,epoch)
            hw.write(R['period'],period)
            if hw.read(R['period'])!=period: raise GuardError('period readback mismatch')
            armed=True  # command may have reached ADC even if reply fails
            start_request=clock()
            control(hw,epoch,1)
            start=clock(); end=start+seconds; last_progress=start
            st=snap(hw,epoch)
            if not st['capture_status'] & CAP_RUN or st['active_period']!=period:
                raise GuardError('START readback mismatch')
            event(j,{'event':'start_accepted','start_request_to_ack_seconds':start-start_request})
            while True:
                if not stopped and clock()>=end:
                    stop_request=clock()
                    control(hw,epoch,2)
                    stop_ack=clock(); stopped=True; drain_end=stop_ack+drain_timeout
                    event(j,{'event':'stop_accepted','host_start_to_stop_request_seconds':stop_request-start})
                if stopped and clock()>=drain_end: raise GuardError('drain timeout')
                st=snap(hw,epoch)
                if st['active_period']!=period or bool(st['capture_status'] & CAP_RUN)==stopped:
                    raise GuardError('unexpected run/period state')
                chosen=choose_bank(st)
                if chosen is None:
                    if stopped and drained(st): break
                    if not stopped and clock()-last_progress>progress_timeout: raise GuardError('frame progress timeout')
                    sleep(.0002); continue
                bank,seq=chosen
                if seq!=(base['completed']+count)&MASK: raise GuardError('sequence discontinuity; NO ACK')
                live(hw,epoch); sample=hw.frame(bank); live(hw,epoch)
                if hw.frame(bank)!=sample: raise GuardError('BRAM changed; NO ACK')
                check=frame_check(sample)
                if check['invalid_flag'] or check['thread_id']!=0: raise GuardError('invalid/non-CH0 frame')
                after=snap(hw,epoch)
                if not same_bank(after,bank,seq): raise GuardError('bank changed; NO ACK')
                pending=seq; offset=count*FRAME_BYTES
                if f.write(sample)!=FRAME_BYTES: raise GuardError('short write')
                f.flush(); os.fsync(f.fileno())
                with data.open('rb') as v:
                    v.seek(offset)
                    if v.read(FRAME_BYTES)!=sample: raise GuardError('disk readback mismatch')
                event(j,{'event':'persisted','sequence':seq,'bank':bank,'epoch':epoch,'offset':offset,'sha256':sha(sample),'host_elapsed_seconds':clock()-start})
                live(hw,epoch); ack(hw,bank,seq,epoch)
                count+=1; digest.update(sample); pending=None; last_progress=clock()
                event(j,{'event':'ack_accepted','sequence':seq,'epoch':epoch})
            delta={k:(st[k]-base[k])&MASK for k in ('started','replayed','completed','skipped')}
            if not count or any(delta[k]!=count for k in ('started','replayed','completed')):
                raise GuardError('final counter reconciliation failed')
            event(j,{'event':'drained','frames':count,'delta':delta,'snapshot':st})
        except BaseException as exc:
            stop_result='not_attempted'
            if armed and not stopped:
                try:
                    # Only same live epoch; never clear protocol errors blindly.
                    control(hw,epoch,2); stop_result='accepted_not_drained'
                except BaseException as stop_exc:
                    stop_result='unconfirmed: '+str(stop_exc)
            elif stopped: stop_result='accepted_drain_unconfirmed'
            try: event(j,{'event':'aborted','error':str(exc),'acked_frames':count,'pending_sequence':pending,'stop':stop_result})
            except BaseException: pass
            print('CAL9_ABORT_STOP:',stop_result,file=sys.stderr)
            raise
    actual=hashlib.sha256()
    with data.open('rb') as v:
        for chunk in iter(lambda:v.read(1024*1024),b''): actual.update(chunk)
    if data.stat().st_size!=count*FRAME_BYTES or actual.hexdigest()!=digest.hexdigest():
        raise GuardError('final file size/hash mismatch')
    summary={'status':'ENGINEERING_RECORDING_COMPLETE_NOT_SCIENCE_SIGNOFF','identity':identity,'epoch':epoch,
             'frames':count,'bytes':count*FRAME_BYTES,'sha256':digest.hexdigest(),'delta':delta,'baseline':base,'final_snapshot':st,
             'requested_seconds':seconds,'host_start_to_stop_request_seconds':stop_request-start,
             'host_start_to_stop_ack_seconds':stop_ack-start,'drain_seconds':clock()-stop_ack,
             'period_cycles':period,'nominal_capture_hz':125000000/period,'gapless':False,
             'skipped_windows':delta['skipped'],'physical_adc_calibrated_by_software':False,'gps_utc_timing_verified':False,
             'durability':'per-frame data fsync/readback and journal fsync before ACK; OS readback not independent media verification'}
    durable_manifest(final,summary)
    return summary

class Mock:
    """Synchronous protocol model, not cycle-accurate RTL or throughput proof."""
    def __init__(self):
        self.reg={k:0 for k in R}; self.reg.update(magic=MAGIC,version=VERSION,avail=1,epoch=7,cal_status=0x1d,period=125000000,active_period=125000000,capture_status=48)
        self.running=False; self.bank=0; self.ready=0; self.n=0; self.acks=0; self.commands=[]; self.corrupt=False; self.reject=False; self.freeze=False; self.lose_epoch=False
        self.data=struct.pack('<8I',0,0x34000000,0x20000084,0x1c005342,0,0,0,0)+bytes(range(256))*4
    def read(self,off): return self.reg[next(k for k,v in R.items() if v==off)]
    def frame(self,bank):
        if self.lose_epoch: self.reg['epoch']+=1; self.lose_epoch=False
        return bytes(FRAME_BYTES) if self.corrupt else self.data
    def produce(self):
        if not self.ready and not self.freeze:
            self.bank=self.n%2; self.ready=1<<self.bank
            self.reg['bank%d_seq'%self.bank]=self.n; self.n+=1
    def write(self,off,value):
        k=next(k for k,v in R.items() if v==off)
        if k=='events': self.reg['state'] &= ~((value&1)*4+((value>>1)&1)*8+((value>>2)&1)*32)
        elif k=='capture_cmd':
            self.commands.append(value); self.running=value==1
            if self.running: self.reg['active_period']=self.reg['period']
            else: self.produce() # model one final pending frame
            self.reg['capture_status']=48+6+(8 if self.running else 0)
        elif k=='command' and value==1:
            if self.running: self.produce()
            self.reg.update(ready=self.ready,started=self.n,replayed=self.n,completed=self.n)
            self.reg['state']|=4
        elif k=='command' and value==2:
            ok=not self.reject and self.reg['ack_epoch']==self.reg['epoch'] and self.reg['ack_bank']==self.bank and self.reg['ack_seq']==self.n-1 and bool(self.ready)
            self.reg['last_ack']=int(ok); self.reg['state']=(self.reg['state']&~16)|8|(16 if ok else 0)
            if ok: self.ready=0; self.acks+=1
        else: self.reg[k]=value

class Tests(unittest.TestCase):
    def run_record(self, hw, d):
        ticks=iter(range(100000)); clock=lambda:next(ticks)*.001
        return record(hw,d,.025,125000000,clock=clock,sleep=lambda _:None)
    def test_record_and_drain(self):
        with tempfile.TemporaryDirectory() as d:
            h=Mock(); r=self.run_record(h,d)
            self.assertEqual(h.commands,[1,2]); self.assertEqual(r['frames'],h.acks); self.assertEqual(h.ready,0); self.assertGreater(h.acks,1)
            self.assertEqual(Path(d,'ch0_cal9.vdif').stat().st_size,h.acks*1056)
            events=[json.loads(x) for x in Path(d,'ch0_cal9.jsonl').read_text().splitlines()]
            self.assertEqual(sum(x['event']=='persisted' for x in events),h.acks)
            self.assertEqual(events[-1]['event'],'drained')
    def test_wrong_abi(self):
        with tempfile.TemporaryDirectory() as d:
            h=Mock(); h.reg['version']=0x10002
            with self.assertRaises(GuardError): self.run_record(h,d)
            self.assertEqual(h.commands,[])
    def test_calibration(self):
        with tempfile.TemporaryDirectory() as d:
            h=Mock(); h.reg['cal_status']=0x13
            with self.assertRaises(GuardError): self.run_record(h,d)
            self.assertEqual(h.commands,[])
    def test_pending_bank(self):
        with tempfile.TemporaryDirectory() as d:
            h=Mock(); h.produce()
            with self.assertRaises(GuardError): self.run_record(h,d)
            self.assertEqual(h.commands,[])
    def test_corrupt(self):
        with tempfile.TemporaryDirectory() as d:
            h=Mock(); h.corrupt=True
            with self.assertRaises(GuardError): self.run_record(h,d)
            self.assertEqual(h.acks,0); self.assertEqual(h.commands,[1,2]); self.assertFalse(Path(d,'ch0_cal9_summary.json').exists())
    def test_ack_rejection(self):
        with tempfile.TemporaryDirectory() as d:
            h=Mock(); h.reject=True
            with self.assertRaises(GuardError): self.run_record(h,d)
            self.assertEqual(h.acks,0); self.assertEqual(Path(d,'ch0_cal9.vdif').stat().st_size,1056)
    def test_epoch_loss(self):
        with tempfile.TemporaryDirectory() as d:
            h=Mock(); h.lose_epoch=True
            with self.assertRaises(GuardError): self.run_record(h,d)
            self.assertEqual(h.acks,0); self.assertEqual(h.commands,[1])
    def test_existing_output(self):
        with tempfile.TemporaryDirectory() as d:
            h=Mock(); Path(d,'ch0_cal9.vdif').write_bytes(b'keep')
            with self.assertRaises(GuardError): self.run_record(h,d)
            self.assertEqual(h.commands,[]); self.assertEqual(Path(d,'ch0_cal9.vdif').read_bytes(),b'keep')
    def test_no_frames(self):
        with tempfile.TemporaryDirectory() as d:
            h=Mock(); h.freeze=True
            with self.assertRaises(GuardError): self.run_record(h,d)
            self.assertEqual(h.commands,[1,2]); self.assertEqual(h.acks,0)

def main(argv=None):
    p=argparse.ArgumentParser(description=__doc__); sub=p.add_subparsers(dest='cmd')
    sub.add_parser('selftest'); r=sub.add_parser('record')
    for flag in ('allow-mmio','confirm-approved-board','confirm-physical-calibration','allow-status-writes','ack-after-save','allow-start-stop'):
        r.add_argument('--'+flag,action='store_true')
    r.add_argument('--output-dir',required=True); r.add_argument('--duration-seconds',type=int,default=300)
    r.add_argument('--period-cycles',type=int,default=125000000)
    args=p.parse_args(argv)
    if args.cmd in (None,'selftest'):
        result=unittest.TextTestRunner(verbosity=2).run(unittest.defaultTestLoader.loadTestsFromTestCase(Tests))
        if result.wasSuccessful(): print('CAL9_RECORDER_OFFLINE_SELFTEST_PASS: YES\nHARDWARE_ACCESSED: NO')
        return 0 if result.wasSuccessful() else 3
    try:
        if not all(getattr(args,k) for k in ('allow_mmio','confirm_approved_board','confirm_physical_calibration','allow_status_writes','ack_after_save','allow_start_stop')):
            raise GuardError('hardware permissions and independent signoff required; NO MMIO')
        if os.name!='posix': raise GuardError('Linux board only')
        if not 1<=args.duration_seconds<=300 or not 12500<=args.period_cycles<=125000000: raise GuardError('invalid duration/period')
        import fcntl
        with open('/run/lock/ch0_cal9_recorder.lock','a') as lock:
            fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
            with LinuxMMIO(True) as hw:
                print(json.dumps(record(hw,args.output_dir,args.duration_seconds,args.period_cycles),indent=2))
        return 0
    except (GuardError,OSError,ValueError,KeyboardInterrupt) as exc:
        print('CAL9_FAIL_CLOSED:',exc,file=sys.stderr); return 2

if __name__=='__main__': sys.exit(main())

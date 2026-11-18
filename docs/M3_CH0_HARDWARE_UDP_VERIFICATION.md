# M3 CH0 — physical ADC to VDIF, BRAM, PS and UDP verification

**Observed:** 18 November 2026  
**Board:** Red Pitaya STEM 125-14 Z7020 4IN v1.3 (XC7Z020)  
**Tools:** Vivado 2025.2; Red Pitaya Linux; Windows PowerShell  
**Checkpoint scope:** one-shot **CH0** frame, including a PS-side **single-datagram** UDP transfer.

This record is based on the captured console outputs, ILA waveform and readback shared during hardware testing. It does **not** establish continuous streaming or all-four-channel operation.

## Data path

```text
Physical CH0 analog input (5 MHz sine)
    -> 14-bit ADC frontend (nominal 125 MS/s; SPI, clock, IDELAY, DDR capture)
    -> 1024 x 14-bit one-shot capture buffer
    -> select data[13:6], XOR 8'h80 (8-bit signed sample representation)
    -> VDIF packetizer (8 x 32-bit header words + 1024 sample bytes)
    -> 32-bit AXI-Stream BRAM writer
    -> dual-port BRAM / AXI BRAM controller
    -> Zynq PS Linux UIO readback
    -> PS Linux UDP socket -> Windows UDP receiver
```

The ILA probe `m25_adc_hi8_0_Dout[7:0]` displays the selected raw upper ADC byte. The VDIF output bus `packet_out_TDATA[31:0]` instead carries **four 8-bit samples per 32-bit payload word**. These are different stages of the pipeline.

## Observations

| Check | Observed outcome |
|---|---|
| FPGA programming | JTAG startup reported HIGH; design was captured with a connected 5 MHz CH0 signal |
| Live ILA | Periodic sine-like waveform on CH0 ADC high-byte probe |
| Captured payload | 1,024 ADC-derived bytes (8 bits each) |
| Waveform periodicity | 25 samples per cycle at nominal 125 MS/s, corresponding to 5.000 MHz |
| Lag-25 correlation | ~0.999857 |
| VDIF header | 8 words (32 bytes); header word 2 = `0x20000084` |
| VDIF payload | 1,024 bytes |
| Complete frame | 264 x 32-bit words = **1,056 bytes** |
| PS readback | Linux read 264 words from `/dev/uio0`, map0 physical address `0x40000000` |
| PS-to-PC UDP | One 1,056-byte datagram sent and received |
| Integrity | Source and received **SHA-256 match exactly** |

### Observed eight-word header

```text
00000000
34000000
20000084
1C005342
00000000
00000000
00000000
00000000
```

### UDP transfer integrity

```text
SOURCE_SHA256: 8A4EB26114DDE17D08F605AB5F390DD8D8A70B3AAE16A7E9143322BC7B9E6D45
RECEIVER_SHA256: 8A4EB26114DDE17D08F605AB5F390DD8D8A70B3AAE16A7E9143322BC7B9E6D45
BYTES_SENT: 1056
RECEIVED_BYTES: 1056
RESULT: M3_UDP_RECEIVE_PASS
```

The FPGA readback happened through PS Linux, and Linux then sent the stored frame over UDP. **This is not FPGA-fabric Ethernet transmission, DMA-based streaming, or sustained packet delivery testing.**

### Verified FPGA artifact identity (local, not published here)

```text
M3_CH0_UDP_VERIFIED.bit
SHA256: 7EC7DCF59AED1F2D01242E0BE3AC060FB05658CAD3DBE2FE84A8C46B3195314E
```

The source and artifact were preserved on the development workstation. **The M3 source snapshot / bitstream is not claimed to be available in this public repository until separately reviewed and uploaded.**

## Limitations and pending checks

- Single channel, one-shot 1,024-sample frame; continuous acquisition and packet loss/recovery are **not** demonstrated.
- CH1, CH2 and CH3 are not yet integrated into the demonstrated hardware pipeline.
- The analog stimulus level/amplitude calibration is not established by this record; the 5 MHz periodicity is the measured result.
- ADC input timing constraints include experimental assumptions; complete hardware timing, clock-loss recovery and the debug/DRC warning review remain outstanding.
- Linux UDP transmission is a single stored-frame transfer; no sustained-rate guarantee is established.
- Independent **fresh-clone Vivado rebuild** has not yet been demonstrated.
- Publication of lab materials, custom/vendor IP, test data and bitstreams requires review before upload to this **public** repo. See [CONTRIBUTING.md](../CONTRIBUTING.md).

## Next work

See [ROADMAP.md](ROADMAP.md). Preserve this milestone as a stable reference while implementing four-channel capture and the continuous/event-based Ethernet path.

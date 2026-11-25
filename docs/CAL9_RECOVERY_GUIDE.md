# CAL9 V3 recovery and deployment guide

25 November 2026 — frozen diagnostic baseline. No IP upgrade or new hardware programming is required for archive recovery.

## Public inspection
Install Git and clone the repository:
```powershell
git clone https://github.com/SwastikAwasthi25/ADC-VDIF-FPGA-Zynq.git
cd ADC-VDIF-FPGA-Zynq
git fsck --full
git switch --detach 524217b3d6c0dfa9730bd91edebd95e7eaad17e6
```
The pinned release contains 44 CAL9 files. Its fresh clone and Git integrity were verified by the operator. It does not include a complete Vivado project.

## Authorized offline recovery
Obtain the lab-approved engineering archive through an authorized channel. Do not distribute withheld third-party dependencies publicly. Required toolchain: Vivado/Vitis HLS 2025.2, XC7Z020-CLG400-1 device support; ARM Linux GCC for host software.

| Artifact | SHA256 |
|---|---|
| CAL9_V3_COMPLETE_ENGINEERING_BACKUP.tar.gz | 07789C7FA1D7ACAA18676B006182B5758E91D9039D3BEAEA7ABA91D47DD1A3CA |
| CAL9_V3_SOURCE_SNAPSHOT.bundle | 843D91FB25941D3AC922DB462B17D4F901E177A8F18806A0944C7E7B45405E77 |
| HISTORICAL_DOWNLOADS_20261125.zip | FDFDCEE5C15F4620862DC6537B514A1ED8A86FA566C276D6D1E599C6EA91E5EC |

In a directory containing the authorized archive, run PowerShell:
```powershell
$archive = (Resolve-Path 'CAL9_V3_COMPLETE_ENGINEERING_BACKUP.tar.gz').Path
$expected = '07789C7FA1D7ACAA18676B006182B5758E91D9039D3BEAEA7ABA91D47DD1A3CA'
if ((Get-FileHash $archive -Algorithm SHA256).Hash -ne $expected) { throw 'Archive hash mismatch' }
$dest = Join-Path (Get-Location) 'CAL9_RESTORED'
if (Test-Path $dest) { throw 'Destination already exists' }
New-Item -ItemType Directory $dest | Out-Null
tar.exe -xzf $archive -C $dest
if ($LASTEXITCODE -ne 0) { throw 'Extraction failed' }
```
Archive creation and listing of 2,005 entries passed. Actual extraction on a new machine and rebuild remain untested. Preserve archive, extracted working copy and original recordings separately. The raw recordings are not guaranteed to be included in this archive. Maintain an authorized backup on a separate physical device.

## Project opening
Open ch0_cal9_gui12.xpr in the restored copy only. Preserve original directory hierarchy. Inspect registered source paths and the two local IP repositories: cal9_local_ip_repo and m3_ch0_integration/m3_continuous_hw_v4/v4_ip_repo. Do not upgrade IP. Preserve packetizer version 1.1 revision 2114830105 and matching reset-repaired HDL. Check the archived firmware hashes against [the frozen baseline](CAL9_AS_TESTED_BASELINE.md). A previous relocated staging project opened with zero locked IPs but twelve unresolved module references. Stop if missing dependencies, incompatible IP or unresolved modules appear; do not silently regenerate or substitute sources. Restore/build qualification is pending.

## Host software
The public CAL9 milestone includes the native V3 recorder and recovery helper. In the authorized ARM Linux environment, compile offline from their source directory:
```sh
gcc -O2 -Wall -Wextra -Werror -std=gnu11 -pthread cal9_native_recorder_v3_candidate_01.c -o cal9_native_recorder_v3
./cal9_native_recorder_v3 --selftest
./cal9_native_recorder_v3 --selftest-fault
```
Run these offline modes in a disposable output directory with sufficient storage. Original ARM compilation and both offline tests passed; these commands are not newly executed by GitHub. Do not invoke live acquisition or access MMIO until board compatibility, ABI, ownership, calibration and operator authorization are established. Existing frozen firmware and matching LTX are the deployment baseline; programming is outside this recovery procedure. Do not use trial constraints as full electrical sign-off.

## Acceptance and limits
Public clone PASS; archive readability PASS; exact firmware hash backup PASS. New-machine restore/build NOT QUALIFIED. Diagnostic CH0 only; DMA HOLD; scientific deployment NO-GO. No gapless or calibrated UTC recording, simultaneous physical four-channel qualification or power-loss durability before ACK is claimed. See [engineering results](CAL9_CH0_DIAGNOSTIC_REPORT.md).

# ADC–VDIF FPGA development roadmap

**Repository:** `SwastikAwasthi25/ADC-VDIF-FPGA-Zynq`  
**Working rule:** preserve previous checkpoints; add changes by reviewable commits/branches and avoid force-pushing `main`.

| Phase | Goal | State |
|---|---|---|
| M2.5 | Simulation + implementation of one-shot ADC–VDIF–BRAM | Previous checkpoint; see [VERIFICATION.md](VERIFICATION.md) |
| M3 CH0 | Real physical ADC input -> VDIF -> BRAM -> PS readback -> one UDP datagram | **Hardware and network proof-of-concept PASS**; see [M3 verification](M3_CH0_HARDWARE_UDP_VERIFICATION.md) |
| M3 source publication | Review local RTL, constraints, custom IP, Vivado metadata and artifact rights; push a portable source snapshot | **Pending** |
| M3 fresh-clone | Recreate project from GitHub on clean Vivado 2025.2 environment | **Pending** |
| M4 | CH0/CH1/CH2/CH3 ADC data integration, consistent channel identity and framing | **Pending** |
| M5 | Re-arm/repeat capture, safe buffer ownership, packet/frame counters, recovery | **Pending** |
| M6 | Repeated PS-side UDP transmission, throughput/loss tests, eventual DMA and event-triggered streaming | **Pending** |
| Payload qualification | Board timing, clock/CDC/reset and physical ADC calibration, systematic hardware tests | **Pending** |

## Streaming bandwidth constraint

At nominal 125 MS/s, four 8-bit channels alone generate **4 Gbit/s** before framing or Ethernet/UDP overhead. Thus an uncompressed, continuous four-channel 125 MS/s stream will not fit on a single 1-Gbit/s Ethernet link. Future design must explicitly choose an event-triggered window, rate reduction, compression, stronger transport, or a combination.

## Source and checkpoints policy

1. Keep historical M2.5 commits intact and do not overwrite them with a new unrelated local `main`.
2. Before publication, audit local FPGA HDL, clock/pin constraints, HLS IP, vendor output, lab restrictions, images/binaries, and credentials. This repo is **public**.
3. Preserve complete **publishable** source/build metadata, not merely a bitstream; link to tool versions, target board, simulation evidence and rebuild commands.
4. A build is only called reproducible after an actual fresh-clone regeneration/rebuild test.
5. Reserve the `M3-CH0-UDP-VERIFIED` release tag for an appropriate source/artifact checkpoint **after** source integration/review, rather than tagging documentation only.
6. Develop four-channel and continuous-streaming changes in separate branches; keep hardware-proven CH0 behavior regression-testable.

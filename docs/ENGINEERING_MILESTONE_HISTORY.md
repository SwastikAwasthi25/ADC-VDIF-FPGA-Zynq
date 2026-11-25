# FPGA engineering milestone history

25 November 2026 | Diagnostic development checkpoint

This record summarizes operator-reported development evidence. It does not substitute for the unpublished source trees or laboratory qualification.

| Milestone | Scope | Outcome |
|---|---|---|
| M1 | HLS VDIF framing and packing | C simulation, synthesis and IP packaging reported PASS |
| M2 / M2.5 | ADC-derived samples, AXI Stream, BRAM and PS readback | Simulated 1024-byte payload and 264-word frame verified; routed prototype |
| DMA3 research | Scatter-gather descriptor processing | Single-descriptor paths worked; multi-descriptor fetch unresolved; HOLD |
| M3 | Physical CH0 acquisition | 5 MHz input and one 1056-byte UDP datagram with matching SHA256 reported |
| M4 | Four-channel capture and VDIF simulation | Four 1024-byte payloads, 4224 total bytes, independent scoreboards and 1575 stall cycles; negative-control and clock-drift tests passed |
| M4 reset | Coordinated reset and HLS reset recovery | Mid-VDIF reset failure isolated; shadow reset patch passed modeled regression |
| CAL8 | SPI checkerboard calibration gate and CDC | Diagnostic integration; full electrical and calibration qualification pending |
| CAL9 V3 | Periodic CH0 acquisition and native concurrent recorder | 299995 frames in 300 seconds; zero reported skips/errors; all recorded headers, sequences and waveform checks passed |

## Design decisions and lessons
- Scatter-gather DMA remains a separate research path; the demonstrated CAL9 recorder uses BRAM ping-pong and ARM readback.
- The periodic capture scheduler separates ADC capture from replay and packetization. Sequence/epoch-qualified acknowledgements protect bank ownership.
- Reset handling must cover HLS internal state, not only interface registers. Modeled four-channel reset tests are not physical qualification.
- Python polling overhead motivated aligned native 32-bit MMIO and C recording. A bounded producer/consumer ring decouples acquisition and storage.
- Acknowledgement after RAM copy is not a guarantee of storage durability.

## Frozen release and recovery
The public CAL9 source checkpoint is commit 524217b3d6c0dfa9730bd91edebd95e7eaad17e6, merged into main via PR #1. Fresh Git clone integrity passed. The authorized engineering archive contains the frozen local project and generated dependencies; archive readability passed, but new-machine restore and build remain unqualified. Historical experiment downloads were archived with per-file SHA256 validation (153 files). Exact firmware and recording evidence are retained offline.

## Historical source branch policy
Do not create placeholder branches that falsely imply a verified source snapshot. The M3 full working tree, M4 source/testbench tree and DMA research tree require actual source export and redistribution review before separate publication. No public binary or restricted IP release is implied.

## Further reading
- [CAL9 engineering results](CAL9_CH0_DIAGNOSTIC_REPORT.md)
- [Frozen firmware baseline](CAL9_AS_TESTED_BASELINE.md)
- [Recovery guide](CAL9_RECOVERY_GUIDE.md)
- [M3 hardware checkpoint](M3_CH0_HARDWARE_UDP_VERIFICATION.md)

Scientific recording NO-GO; DMA HOLD. No new FPGA programming or IP upgrade was performed during release closure.

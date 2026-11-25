# CAL9 CH0 Diagnostic Source Release

## Verified baseline

- FPGA: XC7Z020-CLG400-1
- Toolchain: Vivado 2025.2
- Original project: ch0_cal9_gui12.xpr
- Firmware: CAL9 V3 diagnostic implementation
- ADC sampling clock: nominal 125 MHz
- Periodic capture rate: nominal 1000 frames/s
- VDIF frame: 1056 bytes, including 1024 payload bytes

## Hardware verification

The five-minute diagnostic acquisition recorded 299995 frames.
Hardware counters, recorder counters and offline file checks
reconciled with zero reported skips and zero reported errors.

## Published source

This snapshot includes project-developed recorder software,
capture scheduling, calibration control, reset handling,
CDC mailbox logic, AXI-Lite control and ping-pong buffering.

## Dependencies and redistribution

Third-party SPI RTL and generated AMD/Xilinx HLS IP packages
are withheld pending confirmation of redistribution terms.

The complete local engineering archive retains the original
IP packages and verified firmware artifacts.

Existing copyright and license notices must be preserved.

## Build status

This public source snapshot is not a standalone buildable
Vivado project. Additional dependencies and project metadata
are required.

A separate full local project opened successfully in Vivado
2025.2, but fresh-clone synthesis has not been qualified.

No IP upgrade or firmware redesign is part of this release.

## Qualification limits

- Diagnostic CH0 acquisition only.
- DMA streaming remains on HOLD.
- Gapless continuous sampling is not qualified.
- Absolute GPS/UTC timestamping is not qualified.
- Four-channel physical acquisition is not qualified.
- Scientific recording deployment remains NO-GO.

See docs/CAL9_CH0_DIAGNOSTIC_REPORT.md and
docs/CAL9_AS_TESTED_BASELINE.md for detailed evidence.

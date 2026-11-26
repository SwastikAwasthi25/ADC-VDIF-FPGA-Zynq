# CAL10 CH0 integrated verification — 26 November 2026

**Scope:** operator-executed Vivado XSim 2025.2 simulation, actual RTL and generated HLS packetizer. Not hardware or scientific qualification.

| Regression | Complete frames | Raw samples | VDIF words | Finish (ns) |
|---|---:|---:|---:|---:|
| 9C.6B Fix 1 normal acquisition | 2 | 2048 | 528 | 755500 |
| 9C.6C interrupted reset recovery | 2 | 2048 | 528 | 5389216 |
| 9C.6D Fix 1 backpressure | 4 | 4096 | 1056 | 6689400 |
| Total | 8 | 8192 | 2112 | — |

- Normal: two independent payload scoreboards, 8-bit VDIF field (word 3 = 0x1c005342), full-bank skip accounting, epoch/sequence ACK and STOP. Issue #8 resolved; earlier header expectation was a testbench error.
- Reset: frontend loss after 128 raw samples, epoch 0→1 and stale-epoch rejection; PS reset after 32 writes, partial frame invalidation, fresh frame and ACK/STOP recovery.
- Backpressure: directed header/payload/final-word stalls plus deterministic pseudo-random stalls; bank/sequence 0/0, 1/1, 0/2 and post-reset 0/0. Complete-frame stalls 134+151+191+157 = 633. Reset with 263 accepted/written words and final word held invalidated partial frame; zero observed reset-boundary writes.
- Latest uploaded archive: 10 entries CRC intact; 534 protected entries, previous 515 preserved, empty change report; executed testbench text matches supplied script. Three successful archives share the same 45-file compile order.
- Initial backpressure compile failure was testbench declaration ordering, corrected without production RTL changes.

## Routed baseline

Corrected DCP SHA-256: `8A7251A0B11BBA01EC6DD1453E5452020C75727B1FEF9DF7BB9FF944950BE16A`. WNS +0.540 ns; WHS +0.055 ns under existing constraints; BRAM REQP-1840 findings 3→0. Held-data endpoint checks 301/301; nine functional synchronizer pairs and seven reset stage paths passed scoped structural/timing audits. Physical reset glitch/pulse and full CDC signoff are not established.

## Publication gate

A reviewed local publication bundle has been prepared with 20 functional RTL files, five XDC files, three executed testbenches, selected result markers, 45 ordered dependency hashes (25 generated dependencies withheld), and a new unexecuted portable runner. Bundle SHA-256: `D9E3038DCF89BB79EC19A4F9A751197F4E470CAABD51035D4CCC6AD9ECEE75FE`. Source upload remains pending. Preserve original testbench/source bytes and all existing rights notices. No generated vendor IP, imported SPI source, checkpoints, bitstreams, raw data, full logs or machine-specific paths are included.

## Remaining gates

Issue #3 ADC clock-loss recovery, #4 physical reset qualification, #6 external ADC/SPI timing and sample-rate characterization, #7 historical dependency rights. External ADC stimulus, PS master and memory modeled; actual SmartConnect and AXI BRAM controller outside harness. D8 is not anti-alias qualification; no absolute UTC timestamps, gapless or four-channel physical acquisition established. CAL10 hardware programming remains on hold. CAL9 remains physical diagnostic baseline. Issue #5 stays open until reviewed source/testbench publication is complete.

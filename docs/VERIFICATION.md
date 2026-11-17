# M2.5 verification record

**Reported date:** 2026-11-17  
**Device:** XC7Z020-CLG400-1  
**Tool:** Vivado 2025.2

This document records results reported from the local Vivado console. Raw RTL, simulations, and reports should be added only after review.

## Simulation evidence

### Frame generation

From `tb_m25_adc_vdif_bram_bramtest`:

```text
CAPTURE_DONE=1
REPLAY_DONE=1
SAMPLE_COUNT=1024
ADC_BEATS=1024
PPS_BEATS=1
BRAM_WRITES=264
VDIF_HEADER_0=00000000
VDIF_HEADER_1=34000000
VDIF_HEADER_2=20000084
VDIF_HEADER_3=1c005342
PASS: 1024 samples, 1 PPS, 264 BRAM words
```

### Separate AXI memory readback simulation

From `tb_m25_sc_readback`:

```text
AXI_REQUESTS=264
AXI_RESPONSES=264
AXI_MISMATCHES=0
PASS: 264 AXI4 reads match VDIF packet
```

These are distinct simulation testbenches, not an actual end-to-end ARM readback on the board.

## Synthesis and implementation

```text
SYNTH_STATUS: synth_design Complete!
SYNTH_PROGRESS: 100%
BITSTREAM_STATUS: write_bitstream Complete!
BITSTREAM_PROGRESS: 100%
BITSTREAM_RC: 0
INFO: [Vivado 12-1842] Bitgen Completed Successfully.
```

**Fully routed timing summary:**

| Metric | Value |
|---|---:|
| Setup WNS | +0.270 ns |
| Setup TNS | 0.000 ns |
| Hold WHS | +0.031 ns |
| Hold THS | 0.000 ns |
| Setup failing endpoints | 0 |
| Setup total endpoints | 10,403 |

All *specified* timing constraints were met. This alone does not prove timing coverage is complete.

## Bus-skew checks

The four reported debug-hub CDC FIFO constraints met the 8 ns requirement:

| Check | Actual skew (ns) | Slack (ns) |
|---|---:|---:|
| 1 | 0.749 | +7.251 |
| 2 | 0.701 | +7.299 |
| 3 | 1.021 | +6.979 |
| 4 | 0.760 | +7.240 |

## Unresolved engineering risks

- Before routing, the `check_timing` report identified 1,539 `no_clock` pins and 2,367 unconstrained internal endpoints, with displayed examples in ILA/debug logic. These must not be assumed benign without classification.
- `no_input_delay` identifies `adc_dat_p_i_0[0]` through `adc_dat_p_i_0[6]`. Source-synchronous ADC input timing is not fully specified.
- Post-route DRC reported nine warnings: three `PDCN-1569`, two `REQP-1839`, three `REQP-1840`, and one `RTSTAT-10`. Bitstream precondition DRC subsequently reported zero errors.
- Actual ADC lane mapping, data formatting, physical capture quality, and PS readback remain unverified on hardware.
- Four-channel imported frontend is not integrated into the implemented one-channel block design.

## Scope

The current architecture is **one-shot single-channel acquisition**: 1,024 captured samples become one VDIF frame of 32-byte header + 1,024-byte payload = 264 32-bit words. It is not yet continuous streaming, multi-channel synchronization, GPS PPS discipline, live UDP networking, or lightning localization.

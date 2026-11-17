# ADC–VDIF FPGA on Zynq-7000

FPGA prototyping checkpoint for a single-channel ADC capture path, VDIF packetization, on-chip BRAM storage, and AXI-accessible readback on a Zynq-7000 device.

**Status (17 November 2026):** Vivado 2025.2 simulation, synthesis, place-and-route, and bitstream generation completed. **Physical board capture and Zynq software readback have not yet been demonstrated.**

## Current one-shot design

```text
Differential ADC data + ADC clock
               |
       IBUFDS / IDDR capture
               |
          14-bit samples
               |
   1,024-sample frame buffer
               |
         8-bit AXI-Stream
               |
     VDIF packetizer (PPS)
               |
       32-bit BRAM writer
               |
         Dual-port BRAM
               |
  AXI BRAM Controller / SmartConnect
               |
        Zynq PS interface
```

The packet format used in the verified testbenches is a **32-byte header + 1,024-byte payload**, stored as **264 32-bit words**.

## Verification snapshot

| Check | Observed result |
|---|---|
| ADC-derived frame testbench | 1,024 samples, 1,024 ADC beats, one simulated PPS beat, 264 BRAM writes; PASS |
| Separate AXI readback testbench | 264 reads, 264 responses, zero mismatches; PASS |
| Synthesis | `synth_design Complete!` |
| Implementation | Fully routed |
| Routed timing, constrained paths | WNS +0.270 ns; TNS 0; WHS +0.031 ns |
| Bus skew | 4 reported constraints met |
| Bitstream | `Bitgen Completed Successfully` |

**Caveats:** ADC external input-delay constraints are incomplete for seven data pins; debug-related unconstrained timing paths and nine reported DRC warnings need review. Bitstream generation is **not** proof of correct physical acquisition, debug operation, or timing sign-off. The reported pre-bitstream DRC run had 0 errors.

## Not yet demonstrated

- Physical board programming and reliable live ADC sample capture
- Real PS/ARM software readback of the complete frame
- Multi-channel acquisition (four-channel frontend was separately imported, not connected to this implemented BD)
- Continuous lossless buffering, externally disciplined PPS, UDP streaming, or lightning event localization

## Source availability

Project RTL, reproducible Vivado metadata, and simulation testbenches will be added from the development workstation after a publication/redistribution review. Vendor-generated build output, restricted IP, credentials, and unpublished lab materials must not be committed.

See [verification details](docs/VERIFICATION.md) and [repository safety rules](CONTRIBUTING.md).

## Platform

- AMD Vivado 2025.2
- XC7Z020-CLG400-1 (Zynq-7000)

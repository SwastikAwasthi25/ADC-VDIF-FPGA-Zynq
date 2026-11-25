# Frozen CAL9 V3 as-tested baseline

Date: 25 November 2026. Preserve the exact diagnostic implementation; no IP upgrade or firmware redesign is requested.

- Vivado 2025.2, part xc7z020clg400-1, project `ch0_cal9_gui12.xpr`, top `design_1_wrapper`.
- Programmed diagnostic artifact: `cal9_v3_DIAGNOSTIC_ONLY.bit`, SHA256 `DBBAB7706D2760AA757FAC3A9989A30A9D8A47B7E99F190D542333141E3FFC10`.
- Matching debug probes: `cal9_v3_DIAGNOSTIC_ONLY.ltx`, SHA256 `2B558EC4F52C7CF589126604DBB430687BBC6AAA7CFBEAAA82F275FDF2ADFACF`.
- Routed checkpoint: `cal9_engineering_routed_v3.dcp`, SHA256 `0F015664C3331EF036AB8F7865F446E3B4BBF06FCF2AD1AFCFE4D283DA6E90EE`.
- Packetizer `xilinx.com:hls:vdif_packetizer:1.1`, revision 2114830105; preserve repaired package, not historical 1.0.
- Packer SHA256 `8A8886E5C9DBEAAEC7CA3C0DBA12086AF085035677768F0275142B886EC2AADA`; framer SHA256 `F543E18A5F6DA59EE30FD8C9155294FD61B3F7E1681D580F3F54241AD2B11154`. Both packaged and generated copies matched in operator output.
- Native recorder V3 source SHA256 `ED724BC73DC18E5DFE7B4F8EF5668EF39572D895D8C3B8BB1773DE7008F9B7CE`.

## Relocation inspection
Operator reported a 173-file, 5.3 MiB hash-verified source staging copy. Vivado batch opened the relocated project, registered both local IP repositories, reported zero external or missing registered file paths and zero locked IPs. Packetizer 1.1 reported up-to-date without upgrade. Twelve module references remained unresolved in the IP status report. No output generation or synthesis was run. This is an opening test, not a clean-clone build qualification. The original project previously reported incompatible IP data; exact cause is not established.

## Release policy
Keep the exact tested bitstream, matching LTX, routed checkpoint, sources and generated dependencies in a protected local archive. Public distribution of sources or binaries requires redistribution review. No automatic upgrade, inline HDL migration, or reprogramming. Reviewed public source subset is now on main; restricted IP, project metadata and binary artifacts remain offline. See [recovery guide](CAL9_RECOVERY_GUIDE.md). See the diagnostic report for measured results and limitations. DMA HOLD; scientific deployment NO-GO.

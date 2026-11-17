# Local FPGA source snapshot

- `vivado/design_1.bd`: actual M2.5 bitstream-project block design.
- `vivado/constraints/`: copied existing XDC, **not complete ADC input timing sign-off**.
- `vivado/ip_metadata/`: Vivado `.xci` configuration metadata, **not an exported, independently reproducible IP package**.
- `rtl/m25_bridge_sources/`: candidate bridge/integration RTL retained for provenance; not every file is proven live in the BD.
- `rtl/m25_vivado_support/`: project RTL support sources; not every file is active.
- `rtl/adc_four_channel_imported_not_connected/`: imported four-channel ADC sources, **NOT connected in M2.5 bitstream**.
- `tests/`: original testbench source files; tests were run in distinct configurations. Some require local models or memory vectors not published here.

**This checkout is an auditable code snapshot, not a demonstrated clean-clone build.** HLS design source / export manifest still need to be identified and reviewed. The `.bit`, `.dcp`, generated Vitis/Vivado HDL, experimental backups, and raw sample memories were excluded.

# CAL10 CH0 integrated engineering checkpoint

Simulation-verified source snapshot, 26 November 2026. Not a standalone Vivado project, hardware release or scientific qualification. See the repository engineering checkpoint and Issue #5.

The 20 functional RTL sources and five XDC files are exact copies matching the final protected manifest. The three executed integration testbenches are preserved byte for byte. The 25 generated compile dependencies are deliberately not distributed; their ordered relative paths and SHA-256 hashes are in dependency_manifest.json. Evidence text contains selected exact result markers, with machine paths and host metadata omitted.

## Implementation provenance

The corrected design connects v4_periodic_ch0_0/rst_n to cal9_hls_sync_reset_0/hls_resetn instead of v4_reset_domains_phase4c_0/adc_control_resetn. The BD and generated design_1 HDL are retained offline. Corrected routed DCP SHA-256: 8A7251A0B11BBA01EC6DD1453E5452020C75727B1FEF9DF7BB9FF944950BE16A. The XDC input delays remain trial and SPI output timing is incomplete.

## Re-run with authorized local dependencies

From this directory, use the supplied run_regression.ps1 with the original verified Vivado project directory and Vivado bin directory. It checks all 45 source hashes and each testbench hash before compiling in a new small simulation scratch directory. It does not regenerate IP, copy a full project, synthesize, implement, program hardware, or establish a clean-clone build. This new portable runner has not been executed on Windows; the testbenches themselves were executed successfully using the original guarded operator scripts.

Physical ADC stimulus, PS master and external memory are modeled. Actual packetizer, mailbox, scheduler, AXI control and sink are instantiated; SmartConnect and AXI BRAM controller are outside this simulation boundary. No gapless acquisition, physical CDC/reset, external timing, absolute timestamps, four-channel physical acquisition or anti-alias qualification is implied.

Existing third-party notices and rights remain unchanged; generated vendor IP and imported SPI RTL are excluded.

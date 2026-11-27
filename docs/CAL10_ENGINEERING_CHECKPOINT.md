# CAL10 CH0 engineering checkpoint — 26 November 2026

Status: simulation and routed engineering candidate; CAL10 physical deployment and scientific recording are not qualified. CAL9 remains the last published physical diagnostic milestone. Operator-executed Vivado/XSim 2025.2 results, not CI.

## Measured evidence

| Gate | Observed result |
|---|---|
| D8 raw capture | 1024 logical samples × 14 bits; nominal 125 MHz ADC clock / 8 = 15.625 MS/s during capture; no anti-alias qualification |
| Reset boundary standalone model | 6 complete capture/replay checks |
| Corrected routed timing | WNS +0.540 ns, WHS +0.055 ns; TNS/THS 0 under existing constraints |
| Routing | 11,855 fully routed routable nets; 0 routing errors |
| BRAM reset hazard | REQP-1840 findings reduced from 3 to 0; all three affected control cones passed |
| Held-data mailbox timing | 301 destination endpoints met 6 ns max-delay constraints; minimum slack +0.706 ns |
| Mailbox standalone model | 228-bit snapshot; 10 capture and 4 ACK transactions; 3 reset interruptions; all selected tests passed |
| Functional synchronizer pairs | 9/9 passed structural and stage timing gates; minimum setup/hold +6.807/+0.122 ns |
| Reset stage paths | 7/7 passed; minimum setup/hold +6.736/+0.122 ns; zero intervening logic levels |
| Reset assertion cones | 8/8 matched reviewed topology; adapter input matched expected source |

The targeted BD change moves the periodic capture reset input from raw ADC control reset to the existing synchronous reset adapter output. This is not a blanket CDC waiver. Corrected routed DCP SHA-256: `8A7251A0B11BBA01EC6DD1453E5452020C75727B1FEF9DF7BB9FF944950BE16A`. DCP and complete raw evidence are retained offline.

## Outstanding work

- Common asynchronous reset assertion LUT: physical glitch and minimum pulse-width safety not established.
- ADC clock stop: reproduced limitation; link readiness can remain asserted while a request stalls.
- Integrated AXI, mailbox, scheduler, packetizer and frame-sink recovery remains unqualified.
- 323 CDC report entries remain for disposition; positive held-data slack and functional tests do not constitute full CDC/MTBF signoff.
- Trial ADC input constraints, four missing SPI output delays, debug clock assumptions and scientific sample-rate/aliasing characterization remain open.
- No CAL10 bitstream generation or board programming authorized by these audits.

This is a documentation checkpoint, not a source release or a clean-clone build. Preserve CAL9 and original evidence. Publish source changes only after exact source provenance and rights review.

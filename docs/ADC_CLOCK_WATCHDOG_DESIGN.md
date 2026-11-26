# ADC clock-loss watchdog — Phase 9D.1 (proposal, unverified)

Refs #3. Baseline: merged CAL10 checkpoint 404d01ac2af084a6ebbae498a03a368bb034b96c. Do not change the frozen milestone.

## Observed defect
The existing v4_ps_link_ready_experimental synchronizes ADC reset release, not clock activity. A stopped ADC clock can retain ready and leave the mailbox busy. The mailbox uses synchronous local resets and coordinated reset of request/reply toggles; resetting PS alone cannot safely cancel an ADC-side request.

## Proposed monitor
A divided ADC heartbeat toggle crosses a two-stage ASYNC_REG synchronizer into independent 50 MHz PS clock. Trial divider: 128 ADC cycles per toggle (1.024 us at 125 MHz). Trial timeout: 512 PS cycles (10.24 us). Require three observed transitions before declaring activity. Heartbeat reset must be independent of watchdog-induced acquisition reset. Synchronize release of its independent reset in both clock domains. A stopped PS clock is outside this monitor's coverage. This detects activity, not frequency accuracy or clock quality.

## Recovery contract
On timeout, latch a fault and block new requests/publication. Assert coordinated acquisition reset and invalidate outstanding transactions and bank ownership; retain AXI register access and epoch management. Do not advertise completion for cancelled commands. Treat any ACK or START already executed before detection as uncertain; discard the old acquisition session. Keep reset asserted while clock absent and until recovered heartbeat is qualified. Require explicit software recovery/rearm and fresh epoch before START. Never automatically resume capture. Confirm ADC local synchronous-reset consumers actually see reset edges after clock restarts before releasing reset. Avoid feeding watchdog fault into its own heartbeat reset. Preserve calibration state only if independently justified; otherwise requalify it. Fault status and epoch must remain observable on PS clock.

## Tests
Standalone monitor: startup without ADC clock, normal independent clocks, stop high/low, timeout, resume, repeated loss, independent reset, threshold boundaries, phase variation. Then integrated actual mailbox and sink: pending status/START/STOP/ACK at loss, old reply in flight, partial capture and partial frame, stale epoch rejection, no automatic restart, fresh frame and ACK. Verify no stale bank publication after detection; quantify detection window. Physical CDC, reset assertion and implementation timing remain separate.

No hardware programming or production changes authorized by this proposal.

# CAL9 runtime bundled-data CDC constraints
# Engineering candidate - not physical signoff
# Existing ACK request constraint preserved
# No blanket asynchronous clock group exceptions

set_max_delay 6.000 -datapath_only  -from [get_pins -of_objects [get_cells -hierarchical -filter {IS_SEQUENTIAL && (NAME =~ design_1_i/v4_mailbox_phase4c_0/inst/u_phase4c_mailbox/status_*_held_reg*)}] -filter {REF_PIN_NAME == C}]  -to [get_pins -of_objects [get_cells -hierarchical -filter {IS_SEQUENTIAL && (NAME =~ design_1_i/v4_mailbox_phase4c_0/inst/u_phase4c_mailbox/ps_completed_frames_reg* || NAME =~ design_1_i/v4_mailbox_phase4c_0/inst/u_phase4c_mailbox/ps_scheduler_idle_reg || NAME =~ design_1_i/v4_mailbox_phase4c_0/inst/u_phase4c_mailbox/ps_active_period_reg* || NAME =~ design_1_i/v4_mailbox_phase4c_0/inst/u_phase4c_mailbox/ps_frame_ready_reg* || NAME =~ design_1_i/v4_mailbox_phase4c_0/inst/u_phase4c_mailbox/ps_captures_replayed_reg* || NAME =~ design_1_i/v4_mailbox_phase4c_0/inst/u_phase4c_mailbox/ps_active_run_reg || NAME =~ design_1_i/v4_mailbox_phase4c_0/inst/u_phase4c_mailbox/ps_bank0_sequence_reg* || NAME =~ design_1_i/v4_mailbox_phase4c_0/inst/u_phase4c_mailbox/ps_bank1_sequence_reg* || NAME =~ design_1_i/v4_mailbox_phase4c_0/inst/u_phase4c_mailbox/ps_skipped_windows_reg* || NAME =~ design_1_i/v4_mailbox_phase4c_0/inst/u_phase4c_mailbox/ps_captures_started_reg*)}] -filter {REF_PIN_NAME == D}]


set_max_delay 6.000 -datapath_only  -from [get_pins -of_objects [get_cells -hierarchical -filter {IS_SEQUENTIAL && (NAME =~ design_1_i/v4_mailbox_phase4c_0/inst/u_phase4c_mailbox/capture_enable_held_reg || NAME =~ design_1_i/v4_mailbox_phase4c_0/inst/u_phase4c_mailbox/capture_period_held_reg*)}] -filter {REF_PIN_NAME == C}]  -to [get_pins -of_objects [get_cells -hierarchical -filter {IS_SEQUENTIAL && (NAME =~ design_1_i/v4_mailbox_phase4c_0/inst/u_phase4c_mailbox/adc_period_cycles_reg* || NAME =~ design_1_i/v4_mailbox_phase4c_0/inst/u_phase4c_mailbox/adc_run_enable_reg || NAME =~ design_1_i/v4_mailbox_phase4c_0/inst/u_phase4c_mailbox/capture_result_held_reg)}] -filter {
                REF_PIN_NAME == D ||
                REF_PIN_NAME == CE
            }]


set_max_delay 6.000 -datapath_only  -from [get_pins -of_objects [get_cells -hierarchical -filter {IS_SEQUENTIAL && (NAME =~ design_1_i/v4_mailbox_phase4c_0/inst/u_phase4c_mailbox/ack_result_held_reg)}] -filter {REF_PIN_NAME == C}]  -to [get_pins -of_objects [get_cells -hierarchical -filter {IS_SEQUENTIAL && (NAME =~ design_1_i/v4_mailbox_phase4c_0/inst/u_phase4c_mailbox/ps_ack_accepted_reg)}] -filter {REF_PIN_NAME == D}]


set_max_delay 6.000 -datapath_only  -from [get_pins -of_objects [get_cells -hierarchical -filter {IS_SEQUENTIAL && (NAME =~ design_1_i/v4_mailbox_phase4c_0/inst/u_phase4c_mailbox/capture_result_held_reg)}] -filter {REF_PIN_NAME == C}]  -to [get_pins -of_objects [get_cells -hierarchical -filter {IS_SEQUENTIAL && (NAME =~ design_1_i/v4_mailbox_phase4c_0/inst/u_phase4c_mailbox/ps_capture_accepted_reg)}] -filter {REF_PIN_NAME == D}]


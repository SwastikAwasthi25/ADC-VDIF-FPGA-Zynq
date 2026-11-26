# CH0 Phase4C ACK CDC: pure-XDC five-target experimental datapath limit.
# No Tcl flow control: Vivado XDC parser does NOT accept if/foreach/concat/puts/unset.
# Sources: ack_bank_held_reg (1), ack_seq_held_reg* (32).
# Destinations: adc_sw_ack_valid_reg, adc_sw_ack_bank_reg, adc_ack_finalize_reg,
#               ack_result_held_reg, ack_reply_toggle_reg (five total).
# All object-count and coverage checks are performed in the separate Vivado build Tcl.
# The 6ns bound is an engineering timing TRIAL, NOT a physical CDC/skew sign-off.
set_max_delay 6.000 -datapath_only \
    -from [get_cells -hierarchical -quiet -filter {NAME =~ *u_phase4c_mailbox/ack_bank_held_reg || NAME =~ *u_phase4c_mailbox/ack_seq_held_reg*}] \
    -to [get_cells -hierarchical -quiet -filter {NAME =~ *u_phase4c_mailbox/adc_sw_ack_valid_reg || NAME =~ *u_phase4c_mailbox/adc_sw_ack_bank_reg || NAME =~ *u_phase4c_mailbox/adc_ack_finalize_reg || NAME =~ *u_phase4c_mailbox/ack_result_held_reg || NAME =~ *u_phase4c_mailbox/ack_reply_toggle_reg}]

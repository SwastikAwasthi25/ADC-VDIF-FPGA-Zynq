`timescale 1ns / 1ps
module v4_phase4c_mailbox_bd_ref (
 input wire ps_clk, input wire adc_clk, input wire ps_resetn, input wire adc_resetn,
 input wire ps_status_req, output wire ps_status_busy, output wire ps_status_valid,
 output wire [1:0] ps_frame_ready,
 output wire [31:0] ps_bank0_sequence, output wire [31:0] ps_bank1_sequence,
 output wire [31:0] ps_completed_frames,
 output wire [31:0] ps_captures_started,
 output wire [31:0] ps_captures_replayed,
 output wire [31:0] ps_skipped_windows,
 output wire ps_scheduler_idle,

 input wire ps_capture_req,
 input wire ps_capture_enable,
 input wire [31:0] ps_capture_period,

 output wire ps_capture_busy,
 output wire ps_capture_done,
 output wire ps_capture_accepted,

 output wire ps_active_run,
 output wire [31:0] ps_active_period,

 output wire adc_run_enable,
 output wire [31:0] adc_period_cycles,
 input wire ps_ack_req, input wire ps_ack_bank,
 input wire [31:0] ps_ack_expected_sequence,
 output wire ps_ack_busy, output wire ps_ack_done, output wire ps_ack_accepted,
 input wire [1:0] adc_frame_ready,
 input wire [31:0] adc_bank0_sequence, input wire [31:0] adc_bank1_sequence,
 input wire [31:0] adc_completed_frames,
 input wire [31:0] adc_captures_started,
 input wire [31:0] adc_captures_replayed,
 input wire [31:0] adc_skipped_windows,
 input wire adc_scheduler_idle,
 output wire adc_sw_ack_valid, output wire adc_sw_ack_bank
);
 v4_frame_mailbox_cdc_domains_experimental u_phase4c_mailbox (
 .ps_clk(ps_clk),.adc_clk(adc_clk),.ps_resetn(ps_resetn),.adc_resetn(adc_resetn),
 .ps_status_req(ps_status_req),.ps_status_busy(ps_status_busy),
 .ps_status_valid(ps_status_valid),.ps_frame_ready(ps_frame_ready),
 .ps_bank0_sequence(ps_bank0_sequence),.ps_bank1_sequence(ps_bank1_sequence),
 .ps_completed_frames(ps_completed_frames),
 .ps_captures_started(ps_captures_started),
 .ps_captures_replayed(ps_captures_replayed),
 .ps_skipped_windows(ps_skipped_windows),
 .ps_scheduler_idle(ps_scheduler_idle),

 .ps_capture_req(ps_capture_req),
 .ps_capture_enable(ps_capture_enable),
 .ps_capture_period(ps_capture_period),

 .ps_capture_busy(ps_capture_busy),
 .ps_capture_done(ps_capture_done),
 .ps_capture_accepted(ps_capture_accepted),

 .ps_active_run(ps_active_run),
 .ps_active_period(ps_active_period),

 .adc_run_enable(adc_run_enable),
 .adc_period_cycles(adc_period_cycles),
 .ps_ack_req(ps_ack_req),.ps_ack_bank(ps_ack_bank),
 .ps_ack_expected_sequence(ps_ack_expected_sequence),
 .ps_ack_busy(ps_ack_busy),.ps_ack_done(ps_ack_done),.ps_ack_accepted(ps_ack_accepted),
 .adc_frame_ready(adc_frame_ready),.adc_bank0_sequence(adc_bank0_sequence),
 .adc_bank1_sequence(adc_bank1_sequence),.adc_completed_frames(adc_completed_frames),
 .adc_captures_started(adc_captures_started),
 .adc_captures_replayed(adc_captures_replayed),
 .adc_skipped_windows(adc_skipped_windows),
 .adc_scheduler_idle(adc_scheduler_idle),
 .adc_sw_ack_valid(adc_sw_ack_valid),.adc_sw_ack_bank(adc_sw_ack_bank)
 );
endmodule
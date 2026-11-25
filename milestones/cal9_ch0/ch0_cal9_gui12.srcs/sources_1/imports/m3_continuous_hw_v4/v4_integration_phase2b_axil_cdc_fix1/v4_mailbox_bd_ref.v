`timescale 1ns / 1ps
module v4_mailbox_bd_ref (
 input wire ps_clk, input wire adc_clk, input wire rst_n,
 input wire ps_status_req, output wire ps_status_busy, output wire ps_status_valid,
 output wire [1:0] ps_frame_ready,
 output wire [31:0] ps_bank0_sequence, output wire [31:0] ps_bank1_sequence,
 output wire [31:0] ps_completed_frames,
 input wire ps_ack_req, input wire ps_ack_bank,
 input wire [31:0] ps_ack_expected_sequence,
 output wire ps_ack_busy, output wire ps_ack_done, output wire ps_ack_accepted,
 input wire [1:0] adc_frame_ready,
 input wire [31:0] adc_bank0_sequence, input wire [31:0] adc_bank1_sequence,
 input wire [31:0] adc_completed_frames,
 output wire adc_sw_ack_valid, output wire adc_sw_ack_bank
);
 v4_frame_mailbox_cdc u_verified_core (
 .ps_clk(ps_clk),.adc_clk(adc_clk),.rst_n(rst_n),
 .ps_status_req(ps_status_req),.ps_status_busy(ps_status_busy),
 .ps_status_valid(ps_status_valid),.ps_frame_ready(ps_frame_ready),
 .ps_bank0_sequence(ps_bank0_sequence),.ps_bank1_sequence(ps_bank1_sequence),
 .ps_completed_frames(ps_completed_frames),
 .ps_ack_req(ps_ack_req),.ps_ack_bank(ps_ack_bank),
 .ps_ack_expected_sequence(ps_ack_expected_sequence),
 .ps_ack_busy(ps_ack_busy),.ps_ack_done(ps_ack_done),.ps_ack_accepted(ps_ack_accepted),
 .adc_frame_ready(adc_frame_ready),.adc_bank0_sequence(adc_bank0_sequence),
 .adc_bank1_sequence(adc_bank1_sequence),.adc_completed_frames(adc_completed_frames),
 .adc_sw_ack_valid(adc_sw_ack_valid),.adc_sw_ack_bank(adc_sw_ack_bank)
 );
endmodule
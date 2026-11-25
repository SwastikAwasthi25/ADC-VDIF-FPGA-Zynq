`timescale 1ns / 1ps
// V4 Phase2A scalar-only BD boundary. Intentionally NO AXIS interface
// attributes or s_axis_* pin names: individual scalar nets also feed ILA.
// Verified SystemVerilog core below is kept bit-for-bit unchanged.
module v4_pingpong_scalar_ref (
    input  wire clk,
    input  wire rst_n,
    input  wire [31:0] in_word,
    input  wire in_valid,
    input  wire in_last,
    output wire out_ready,
    output wire [31:0] bram_addr,
    output wire [31:0] bram_data,
    output wire bram_we,
    output wire [1:0] frame_ready,
    output wire [31:0] bank0_sequence,
    output wire [31:0] bank1_sequence,
    input  wire sw_ack_valid,
    input  wire sw_ack_bank,
    output wire [31:0] completed_frames,
    output wire [31:0] malformed_frames,
    output wire [31:0] blocked_cycles,
    output wire [31:0] blocked_episodes,
    output wire [31:0] rejected_acks
);
    vdif_pingpong_frame_sink u_verified_core (
        .clk(clk), .rst_n(rst_n),
        .s_axis_tdata(in_word), .s_axis_tvalid(in_valid),
        .s_axis_tlast(in_last), .s_axis_tready(out_ready),
        .bram_addr(bram_addr), .bram_data(bram_data), .bram_we(bram_we),
        .frame_ready(frame_ready),
        .bank0_sequence(bank0_sequence), .bank1_sequence(bank1_sequence),
        .sw_ack_valid(sw_ack_valid), .sw_ack_bank(sw_ack_bank),
        .completed_frames(completed_frames), .malformed_frames(malformed_frames),
        .blocked_cycles(blocked_cycles), .blocked_episodes(blocked_episodes),
        .rejected_acks(rejected_acks)
    );
endmodule
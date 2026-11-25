`timescale 1ns / 1ps
// V4 Phase2A Fix1: Verilog-only BD module reference boundary.
// No edits to the hash-verified ping-pong sink core.
module v4_pingpong_ref (
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 clk CLK" *)
    (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME clk, ASSOCIATED_BUSIF s_axis, ASSOCIATED_RESET rst_n" *)
    input wire clk,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 rst_n RST" *)
    (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME rst_n, POLARITY ACTIVE_LOW" *)
    input wire rst_n,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis TDATA" *)
    input wire [31:0] s_axis_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis TVALID" *)
    input wire s_axis_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis TLAST" *)
    input wire s_axis_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis TREADY" *)
    output wire s_axis_tready,
    output wire [31:0] bram_addr,
    output wire [31:0] bram_data,
    output wire bram_we,
    output wire [1:0] frame_ready,
    output wire [31:0] bank0_sequence,
    output wire [31:0] bank1_sequence,
    input wire sw_ack_valid,
    input wire sw_ack_bank,
    output wire [31:0] completed_frames,
    output wire [31:0] malformed_frames,
    output wire [31:0] blocked_cycles,
    output wire [31:0] blocked_episodes,
    output wire [31:0] rejected_acks
);
    vdif_pingpong_frame_sink u_verified_core (
        .clk(clk), .rst_n(rst_n),
        .s_axis_tdata(s_axis_tdata), .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tlast(s_axis_tlast), .s_axis_tready(s_axis_tready),
        .bram_addr(bram_addr), .bram_data(bram_data), .bram_we(bram_we),
        .frame_ready(frame_ready), .bank0_sequence(bank0_sequence),
        .bank1_sequence(bank1_sequence),
        .sw_ack_valid(sw_ack_valid), .sw_ack_bank(sw_ack_bank),
        .completed_frames(completed_frames), .malformed_frames(malformed_frames),
        .blocked_cycles(blocked_cycles), .blocked_episodes(blocked_episodes),
        .rejected_acks(rejected_acks)
    );
endmodule
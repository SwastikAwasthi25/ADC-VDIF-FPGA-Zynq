`timescale 1ns / 1ps
// V4 Phase2A Fix1: Verilog-only BD module reference boundary.
// Verified SystemVerilog core remains unchanged and separately registered.
module v4_periodic_ch0_ref (
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 clk CLK" *)
    (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME clk, ASSOCIATED_BUSIF m_axis, ASSOCIATED_RESET rst_n" *)
    input wire clk,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 rst_n RST" *)
    (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME rst_n, POLARITY ACTIVE_LOW" *)
    input wire rst_n,
    input wire frontend_ready,
    input wire capture_enable,
    input wire run_enable_adc,
    input wire [31:0] period_cycles_adc,
    output wire scheduler_idle,
    input wire sink_slot_free,
    input wire [13:0] adc_raw_ch0,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis TDATA" *)
    output wire [7:0] m_axis_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis TVALID" *)
    output wire m_axis_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis TREADY" *)
    input wire m_axis_tready,
    output wire capture_done,
    output wire replay_done,
    output wire [10:0] sample_count,
    output wire start_capture_pulse,
    output wire [31:0] captures_started,
    output wire [31:0] captures_replayed,
    output wire [31:0] skipped_windows
);
    adc_ch0_periodic_live_bridge u_verified_core (
        .clk(clk), .rst_n(rst_n), .frontend_ready(frontend_ready),
        .capture_enable(capture_enable),
        .run_enable_adc(run_enable_adc),
        .period_cycles_adc(period_cycles_adc),
        .scheduler_idle(scheduler_idle),
        .sink_slot_free(sink_slot_free),
        .adc_raw_ch0(adc_raw_ch0),
        .m_axis_tdata(m_axis_tdata), .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .capture_done(capture_done), .replay_done(replay_done),
        .sample_count(sample_count), .start_capture_pulse(start_capture_pulse),
        .captures_started(captures_started), .captures_replayed(captures_replayed),
        .skipped_windows(skipped_windows)
    );
endmodule
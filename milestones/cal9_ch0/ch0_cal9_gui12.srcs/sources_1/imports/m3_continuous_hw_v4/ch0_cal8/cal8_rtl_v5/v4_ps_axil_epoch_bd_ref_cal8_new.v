`timescale 1ns / 1ps
// AXI-Lite 32-bit PS-register slave wrapper. Core is unchanged SV.
module v4_ps_axil_epoch_bd_ref_cal8_new (
 (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 s_axi_aclk CLK" *)
 (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME s_axi_aclk, ASSOCIATED_BUSIF S_AXI, ASSOCIATED_RESET rst_n" *)
 input wire s_axi_aclk,
 (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 rst_n RST" *)
 (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME rst_n, POLARITY ACTIVE_LOW" *)
 input wire rst_n,
 input wire frontend_online,
 (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWADDR" *)
 (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME S_AXI, PROTOCOL AXI4LITE, DATA_WIDTH 32, ADDR_WIDTH 12, READ_WRITE_MODE READ_WRITE" *)
 input wire [11:0] s_axi_awaddr,
 (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWPROT" *) input wire [2:0] s_axi_awprot, // intentionally ignored by this read/write-only register core
 (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWVALID" *) input wire s_axi_awvalid,
 (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWREADY" *) output wire s_axi_awready,
 (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WDATA" *) input wire [31:0] s_axi_wdata,
 (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WSTRB" *) input wire [3:0] s_axi_wstrb,
 (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WVALID" *) input wire s_axi_wvalid,
 (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WREADY" *) output wire s_axi_wready,
 (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI BRESP" *) output wire [1:0] s_axi_bresp,
 (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI BVALID" *) output wire s_axi_bvalid,
 (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI BREADY" *) input wire s_axi_bready,
 (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARADDR" *) input wire [11:0] s_axi_araddr,
 (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARPROT" *) input wire [2:0] s_axi_arprot, // intentionally ignored by this read/write-only register core
 (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARVALID" *) input wire s_axi_arvalid,
 (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARREADY" *) output wire s_axi_arready,
 (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RDATA" *) output wire [31:0] s_axi_rdata,
 (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RRESP" *) output wire [1:0] s_axi_rresp,
 (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RVALID" *) output wire s_axi_rvalid,
 (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RREADY" *) input wire s_axi_rready,
 output wire ps_status_req, input wire ps_status_busy,
 input wire ps_status_valid, input wire [1:0] ps_frame_ready,
 input wire [31:0] ps_bank0_sequence, input wire [31:0] ps_bank1_sequence,
 input wire [31:0] ps_completed_frames,

 input wire [31:0] ps_captures_started,
 input wire [31:0] ps_captures_replayed,
 input wire [31:0] ps_skipped_windows,
 input wire ps_scheduler_idle,

 input wire ps_active_run,
 input wire [31:0] ps_active_period,

 output wire ps_capture_req,
 output wire ps_capture_enable,
 output wire [31:0] ps_capture_period,

 input wire ps_capture_busy,
 input wire ps_capture_done,
 input wire ps_capture_accepted,
 output wire ps_ack_req, output wire ps_ack_bank,
 output wire [31:0] ps_ack_expected_sequence,
 input wire ps_ack_busy, input wire ps_ack_done, input wire ps_ack_accepted,
 output wire cal_exit_req_ps, input wire spi_initialized_ps,
 input wire pattern_active_ps, input wire normal_ready_ps
);
 v4_ps_axil_control_epoch u_epoch_core (
 .s_axi_aclk(s_axi_aclk),.rst_n(rst_n),.frontend_online(frontend_online),
 .s_axi_awaddr(s_axi_awaddr),.s_axi_awvalid(s_axi_awvalid),.s_axi_awready(s_axi_awready),
 .s_axi_wdata(s_axi_wdata),.s_axi_wstrb(s_axi_wstrb),.s_axi_wvalid(s_axi_wvalid),
 .s_axi_wready(s_axi_wready),.s_axi_bresp(s_axi_bresp),.s_axi_bvalid(s_axi_bvalid),
 .s_axi_bready(s_axi_bready),.s_axi_araddr(s_axi_araddr),
 .s_axi_arvalid(s_axi_arvalid),.s_axi_arready(s_axi_arready),
 .s_axi_rdata(s_axi_rdata),.s_axi_rresp(s_axi_rresp),.s_axi_rvalid(s_axi_rvalid),
 .s_axi_rready(s_axi_rready),
 .ps_status_req(ps_status_req),.ps_status_busy(ps_status_busy),
 .ps_status_valid(ps_status_valid),.ps_frame_ready(ps_frame_ready),
 .ps_bank0_sequence(ps_bank0_sequence),.ps_bank1_sequence(ps_bank1_sequence),
 .ps_completed_frames(ps_completed_frames),

 .ps_captures_started(ps_captures_started),
 .ps_captures_replayed(ps_captures_replayed),
 .ps_skipped_windows(ps_skipped_windows),
 .ps_scheduler_idle(ps_scheduler_idle),

 .ps_active_run(ps_active_run),
 .ps_active_period(ps_active_period),

 .ps_capture_req(ps_capture_req),
 .ps_capture_enable(ps_capture_enable),
 .ps_capture_period(ps_capture_period),

 .ps_capture_busy(ps_capture_busy),
 .ps_capture_done(ps_capture_done),
 .ps_capture_accepted(ps_capture_accepted),.ps_ack_req(ps_ack_req),
 .ps_ack_bank(ps_ack_bank),.ps_ack_expected_sequence(ps_ack_expected_sequence),
 .ps_ack_busy(ps_ack_busy),.ps_ack_done(ps_ack_done),.ps_ack_accepted(ps_ack_accepted),
 .cal_exit_req_ps(cal_exit_req_ps),.spi_initialized_ps(spi_initialized_ps),
 .pattern_active_ps(pattern_active_ps),.normal_ready_ps(normal_ready_ps)
 );
endmodule
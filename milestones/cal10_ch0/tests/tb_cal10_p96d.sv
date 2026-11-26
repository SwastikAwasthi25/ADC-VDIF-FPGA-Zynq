`timescale 1ns/1ps
module tb_cal10_p96d;
  wire [31:0] malformed_frames;
  wire [3:0] packet_keep,packet_strb;
  wire sink_ready;
  reg allow_transfer=1;
  wire Net;
  assign Net=sink_ready && allow_transfer;
  wire adc_ch0_live_bridge_0_capture_done;
  wire [11:0]axi_smc_M01_AXI_ARADDR;
  wire [2:0]axi_smc_M01_AXI_ARPROT;
  wire axi_smc_M01_AXI_ARREADY;
  wire axi_smc_M01_AXI_ARVALID;
  wire [11:0]axi_smc_M01_AXI_AWADDR;
  wire [2:0]axi_smc_M01_AXI_AWPROT;
  wire axi_smc_M01_AXI_AWREADY;
  wire axi_smc_M01_AXI_AWVALID;
  wire axi_smc_M01_AXI_BREADY;
  wire [1:0]axi_smc_M01_AXI_BRESP;
  wire axi_smc_M01_AXI_BVALID;
  wire [31:0]axi_smc_M01_AXI_RDATA;
  wire axi_smc_M01_AXI_RREADY;
  wire [1:0]axi_smc_M01_AXI_RRESP;
  wire axi_smc_M01_AXI_RVALID;
  wire [31:0]axi_smc_M01_AXI_WDATA;
  wire axi_smc_M01_AXI_WREADY;
  wire [3:0]axi_smc_M01_AXI_WSTRB;
  wire axi_smc_M01_AXI_WVALID;
  wire [31:0]axis_bram_writer_0_bram_addr;
  wire [31:0]axis_bram_writer_0_bram_data;
  wire axis_bram_writer_0_bram_we;
  wire axis_bram_writer_0_packet_done;
  wire cal9_hls_sync_reset_0_hls_resetn;
  wire cal9_hls_sync_reset_0_stream_enable;
  wire cal9_stream_isolation_0_adc_r_o;
  wire cal9_stream_isolation_0_adc_v_o;
  wire cal9_stream_isolation_0_pkt_r_o;
  wire cal9_stream_isolation_0_pkt_v_o;
  wire cal9_stream_isolation_0_pps_r_o;
  wire cal9_stream_isolation_0_pps_v_o;
  wire ch0_oneshot_gate_0_capture_enable;
  wire [7:0]m25_pps_once_0_m_axis_tdata;
  wire m25_pps_once_0_m_axis_tvalid;
  wire m3_adc_spi_ch0_bridge_0_ch0_clk;
  wire [13:0]m3_adc_spi_ch0_bridge_0_ch0_raw;
  wire m3_adc_spi_ch0_bridge_0_frontend_ready;
  wire m3_adc_spi_ch0_bridge_0_normal_ready_ps;
  wire m3_adc_spi_ch0_bridge_0_pattern_active_ps;
  wire m3_adc_spi_ch0_bridge_0_spi_initialized_ps;
  wire processing_system7_0_FCLK_CLK0;
  wire [0:0]rst_ps7_0_50M_peripheral_aresetn;
  wire v4_link_ready_phase4c_0_frontend_online_ps;
  wire v4_mailbox_0_adc_sw_ack_bank;
  wire v4_mailbox_0_adc_sw_ack_valid;
  wire v4_mailbox_0_ps_ack_accepted;
  wire v4_mailbox_0_ps_ack_busy;
  wire v4_mailbox_0_ps_ack_done;
  wire [31:0]v4_mailbox_0_ps_bank0_sequence;
  wire [31:0]v4_mailbox_0_ps_bank1_sequence;
  wire [31:0]v4_mailbox_0_ps_completed_frames;
  wire [1:0]v4_mailbox_0_ps_frame_ready;
  wire v4_mailbox_0_ps_status_busy;
  wire v4_mailbox_0_ps_status_valid;
  wire [31:0]v4_mailbox_phase4c_0_adc_period_cycles;
  wire v4_mailbox_phase4c_0_adc_run_enable;
  wire [31:0]v4_mailbox_phase4c_0_ps_active_period;
  wire v4_mailbox_phase4c_0_ps_active_run;
  wire v4_mailbox_phase4c_0_ps_capture_accepted;
  wire v4_mailbox_phase4c_0_ps_capture_busy;
  wire v4_mailbox_phase4c_0_ps_capture_done;
  wire [31:0]v4_mailbox_phase4c_0_ps_captures_replayed;
  wire [31:0]v4_mailbox_phase4c_0_ps_captures_started;
  wire v4_mailbox_phase4c_0_ps_scheduler_idle;
  wire [31:0]v4_mailbox_phase4c_0_ps_skipped_windows;
  wire [31:0]v4_periodic_ch0_0_captures_replayed;
  wire [31:0]v4_periodic_ch0_0_captures_started;
  wire [7:0]v4_periodic_ch0_0_m_axis_tdata;
  wire v4_periodic_ch0_0_m_axis_tvalid;
  wire v4_periodic_ch0_0_scheduler_idle;
  wire [31:0]v4_periodic_ch0_0_skipped_windows;
  wire [1:0]v4_pingpong_0_frame_ready;
  wire [31:0]v4_pingpong_scalar_0_bank0_sequence;
  wire [31:0]v4_pingpong_scalar_0_bank1_sequence;
  wire [31:0]v4_pingpong_scalar_0_completed_frames;
  wire v4_ps_axil_0_ps_ack_bank;
  wire [31:0]v4_ps_axil_0_ps_ack_expected_sequence;
  wire v4_ps_axil_0_ps_ack_req;
  wire v4_ps_axil_0_ps_status_req;
  wire v4_ps_axil_epoch_0_cal_exit_req_ps;
  wire v4_ps_axil_epoch_0_ps_capture_enable;
  wire [31:0]v4_ps_axil_epoch_0_ps_capture_period;
  wire v4_ps_axil_epoch_0_ps_capture_req;
  wire v4_reset_domains_phase4c_0_adc_control_resetn;
  wire v4_reset_domains_phase4c_0_ps_control_resetn;
  wire v4_slot_gate_0_sink_slot_free;
  wire vdif_packetizer_0_adc_in_TREADY;
  wire [31:0]vdif_packetizer_0_packet_out_TDATA;
  wire [0:0]vdif_packetizer_0_packet_out_TLAST;
  wire vdif_packetizer_0_packet_out_TVALID;
  wire vdif_packetizer_0_pps_in_TREADY;
  design_1_cal9_hls_sync_reset_0_0 cal9_hls_sync_reset_0
       (.adc_clk(m3_adc_spi_ch0_bridge_0_ch0_clk),
        .adc_control_resetn(v4_reset_domains_phase4c_0_adc_control_resetn),
        .hls_resetn(cal9_hls_sync_reset_0_hls_resetn),
        .stream_enable(cal9_hls_sync_reset_0_stream_enable));
  design_1_cal9_stream_isolation_0_0 cal9_stream_isolation_0
       (.adc_r_i(vdif_packetizer_0_adc_in_TREADY),
        .adc_r_o(cal9_stream_isolation_0_adc_r_o),
        .adc_v_i(v4_periodic_ch0_0_m_axis_tvalid),
        .adc_v_o(cal9_stream_isolation_0_adc_v_o),
        .pkt_r_i(Net),
        .pkt_r_o(cal9_stream_isolation_0_pkt_r_o),
        .pkt_v_i(vdif_packetizer_0_packet_out_TVALID),
        .pkt_v_o(cal9_stream_isolation_0_pkt_v_o),
        .pps_r_i(vdif_packetizer_0_pps_in_TREADY),
        .pps_r_o(cal9_stream_isolation_0_pps_r_o),
        .pps_v_i(m25_pps_once_0_m_axis_tvalid),
        .pps_v_o(cal9_stream_isolation_0_pps_v_o),
        .stream_enable(cal9_hls_sync_reset_0_stream_enable));
  design_1_ch0_oneshot_gate_0_0 ch0_oneshot_gate_0
       (.capture_enable(ch0_oneshot_gate_0_capture_enable),
        .captures_started(v4_periodic_ch0_0_captures_started),
        .clk(m3_adc_spi_ch0_bridge_0_ch0_clk),
        .frontend_ready(m3_adc_spi_ch0_bridge_0_frontend_ready),
        .rst_n(v4_reset_domains_phase4c_0_adc_control_resetn));
  design_1_m25_pps_once_0_0 m25_pps_once_0
       (.clk(m3_adc_spi_ch0_bridge_0_ch0_clk),
        .m_axis_tdata(m25_pps_once_0_m_axis_tdata),
        .m_axis_tready(cal9_stream_isolation_0_pps_r_o),
        .m_axis_tvalid(m25_pps_once_0_m_axis_tvalid),
        .rst_n(cal9_hls_sync_reset_0_hls_resetn));
  design_1_v4_link_ready_phase4c_0_0 v4_link_ready_phase4c_0
       (.adc_control_resetn(v4_reset_domains_phase4c_0_adc_control_resetn),
        .frontend_online_ps(v4_link_ready_phase4c_0_frontend_online_ps),
        .ps_clk(processing_system7_0_FCLK_CLK0),
        .ps_control_resetn(v4_reset_domains_phase4c_0_ps_control_resetn),
        .ps_peripheral_aresetn(rst_ps7_0_50M_peripheral_aresetn));
  design_1_v4_mailbox_phase4c_0_0 v4_mailbox_phase4c_0
       (.adc_bank0_sequence(v4_pingpong_scalar_0_bank0_sequence),
        .adc_bank1_sequence(v4_pingpong_scalar_0_bank1_sequence),
        .adc_captures_replayed(v4_periodic_ch0_0_captures_replayed),
        .adc_captures_started(v4_periodic_ch0_0_captures_started),
        .adc_clk(m3_adc_spi_ch0_bridge_0_ch0_clk),
        .adc_completed_frames(v4_pingpong_scalar_0_completed_frames),
        .adc_frame_ready(v4_pingpong_0_frame_ready),
        .adc_period_cycles(v4_mailbox_phase4c_0_adc_period_cycles),
        .adc_resetn(v4_reset_domains_phase4c_0_adc_control_resetn),
        .adc_run_enable(v4_mailbox_phase4c_0_adc_run_enable),
        .adc_scheduler_idle(v4_periodic_ch0_0_scheduler_idle),
        .adc_skipped_windows(v4_periodic_ch0_0_skipped_windows),
        .adc_sw_ack_bank(v4_mailbox_0_adc_sw_ack_bank),
        .adc_sw_ack_valid(v4_mailbox_0_adc_sw_ack_valid),
        .ps_ack_accepted(v4_mailbox_0_ps_ack_accepted),
        .ps_ack_bank(v4_ps_axil_0_ps_ack_bank),
        .ps_ack_busy(v4_mailbox_0_ps_ack_busy),
        .ps_ack_done(v4_mailbox_0_ps_ack_done),
        .ps_ack_expected_sequence(v4_ps_axil_0_ps_ack_expected_sequence),
        .ps_ack_req(v4_ps_axil_0_ps_ack_req),
        .ps_active_period(v4_mailbox_phase4c_0_ps_active_period),
        .ps_active_run(v4_mailbox_phase4c_0_ps_active_run),
        .ps_bank0_sequence(v4_mailbox_0_ps_bank0_sequence),
        .ps_bank1_sequence(v4_mailbox_0_ps_bank1_sequence),
        .ps_capture_accepted(v4_mailbox_phase4c_0_ps_capture_accepted),
        .ps_capture_busy(v4_mailbox_phase4c_0_ps_capture_busy),
        .ps_capture_done(v4_mailbox_phase4c_0_ps_capture_done),
        .ps_capture_enable(v4_ps_axil_epoch_0_ps_capture_enable),
        .ps_capture_period(v4_ps_axil_epoch_0_ps_capture_period),
        .ps_capture_req(v4_ps_axil_epoch_0_ps_capture_req),
        .ps_captures_replayed(v4_mailbox_phase4c_0_ps_captures_replayed),
        .ps_captures_started(v4_mailbox_phase4c_0_ps_captures_started),
        .ps_clk(processing_system7_0_FCLK_CLK0),
        .ps_completed_frames(v4_mailbox_0_ps_completed_frames),
        .ps_frame_ready(v4_mailbox_0_ps_frame_ready),
        .ps_resetn(v4_reset_domains_phase4c_0_ps_control_resetn),
        .ps_scheduler_idle(v4_mailbox_phase4c_0_ps_scheduler_idle),
        .ps_skipped_windows(v4_mailbox_phase4c_0_ps_skipped_windows),
        .ps_status_busy(v4_mailbox_0_ps_status_busy),
        .ps_status_req(v4_ps_axil_0_ps_status_req),
        .ps_status_valid(v4_mailbox_0_ps_status_valid));
  design_1_v4_periodic_ch0_0_0 v4_periodic_ch0_0
       (.adc_raw_ch0(m3_adc_spi_ch0_bridge_0_ch0_raw),
        .capture_done(adc_ch0_live_bridge_0_capture_done),
        .capture_enable(ch0_oneshot_gate_0_capture_enable),
        .captures_replayed(v4_periodic_ch0_0_captures_replayed),
        .captures_started(v4_periodic_ch0_0_captures_started),
        .clk(m3_adc_spi_ch0_bridge_0_ch0_clk),
        .frontend_ready(m3_adc_spi_ch0_bridge_0_frontend_ready),
        .m_axis_tdata(v4_periodic_ch0_0_m_axis_tdata),
        .m_axis_tready(cal9_stream_isolation_0_adc_r_o),
        .m_axis_tvalid(v4_periodic_ch0_0_m_axis_tvalid),
        .period_cycles_adc(v4_mailbox_phase4c_0_adc_period_cycles),
        .rst_n(cal9_hls_sync_reset_0_hls_resetn),
        .run_enable_adc(v4_mailbox_phase4c_0_adc_run_enable),
        .scheduler_idle(v4_periodic_ch0_0_scheduler_idle),
        .sink_slot_free(v4_slot_gate_0_sink_slot_free),
        .skipped_windows(v4_periodic_ch0_0_skipped_windows),
        .start_capture_pulse(axis_bram_writer_0_packet_done));
  design_1_v4_pingpong_scalar_0_0 v4_pingpong_scalar_0
       (.bank0_sequence(v4_pingpong_scalar_0_bank0_sequence),
        .bank1_sequence(v4_pingpong_scalar_0_bank1_sequence),
        .bram_addr(axis_bram_writer_0_bram_addr),
        .bram_data(axis_bram_writer_0_bram_data),
        .bram_we(axis_bram_writer_0_bram_we),
        .clk(m3_adc_spi_ch0_bridge_0_ch0_clk),
        .completed_frames(v4_pingpong_scalar_0_completed_frames),
        .malformed_frames(malformed_frames),
        .frame_ready(v4_pingpong_0_frame_ready),
        .in_last(vdif_packetizer_0_packet_out_TLAST),
        .in_valid(cal9_stream_isolation_0_pkt_v_o && allow_transfer),
        .in_word(vdif_packetizer_0_packet_out_TDATA),
        .out_ready(sink_ready),
        .rst_n(v4_reset_domains_phase4c_0_adc_control_resetn),
        .sw_ack_bank(v4_mailbox_0_adc_sw_ack_bank),
        .sw_ack_valid(v4_mailbox_0_adc_sw_ack_valid));
  design_1_c8axi_tmp_0 v4_ps_axil_epoch_0
       (.cal_exit_req_ps(v4_ps_axil_epoch_0_cal_exit_req_ps),
        .frontend_online(v4_link_ready_phase4c_0_frontend_online_ps),
        .normal_ready_ps(m3_adc_spi_ch0_bridge_0_normal_ready_ps),
        .pattern_active_ps(m3_adc_spi_ch0_bridge_0_pattern_active_ps),
        .ps_ack_accepted(v4_mailbox_0_ps_ack_accepted),
        .ps_ack_bank(v4_ps_axil_0_ps_ack_bank),
        .ps_ack_busy(v4_mailbox_0_ps_ack_busy),
        .ps_ack_done(v4_mailbox_0_ps_ack_done),
        .ps_ack_expected_sequence(v4_ps_axil_0_ps_ack_expected_sequence),
        .ps_ack_req(v4_ps_axil_0_ps_ack_req),
        .ps_active_period(v4_mailbox_phase4c_0_ps_active_period),
        .ps_active_run(v4_mailbox_phase4c_0_ps_active_run),
        .ps_bank0_sequence(v4_mailbox_0_ps_bank0_sequence),
        .ps_bank1_sequence(v4_mailbox_0_ps_bank1_sequence),
        .ps_capture_accepted(v4_mailbox_phase4c_0_ps_capture_accepted),
        .ps_capture_busy(v4_mailbox_phase4c_0_ps_capture_busy),
        .ps_capture_done(v4_mailbox_phase4c_0_ps_capture_done),
        .ps_capture_enable(v4_ps_axil_epoch_0_ps_capture_enable),
        .ps_capture_period(v4_ps_axil_epoch_0_ps_capture_period),
        .ps_capture_req(v4_ps_axil_epoch_0_ps_capture_req),
        .ps_captures_replayed(v4_mailbox_phase4c_0_ps_captures_replayed),
        .ps_captures_started(v4_mailbox_phase4c_0_ps_captures_started),
        .ps_completed_frames(v4_mailbox_0_ps_completed_frames),
        .ps_frame_ready(v4_mailbox_0_ps_frame_ready),
        .ps_scheduler_idle(v4_mailbox_phase4c_0_ps_scheduler_idle),
        .ps_skipped_windows(v4_mailbox_phase4c_0_ps_skipped_windows),
        .ps_status_busy(v4_mailbox_0_ps_status_busy),
        .ps_status_req(v4_ps_axil_0_ps_status_req),
        .ps_status_valid(v4_mailbox_0_ps_status_valid),
        .rst_n(rst_ps7_0_50M_peripheral_aresetn),
        .s_axi_aclk(processing_system7_0_FCLK_CLK0),
        .s_axi_araddr(axi_smc_M01_AXI_ARADDR),
        .s_axi_arprot(axi_smc_M01_AXI_ARPROT),
        .s_axi_arready(axi_smc_M01_AXI_ARREADY),
        .s_axi_arvalid(axi_smc_M01_AXI_ARVALID),
        .s_axi_awaddr(axi_smc_M01_AXI_AWADDR),
        .s_axi_awprot(axi_smc_M01_AXI_AWPROT),
        .s_axi_awready(axi_smc_M01_AXI_AWREADY),
        .s_axi_awvalid(axi_smc_M01_AXI_AWVALID),
        .s_axi_bready(axi_smc_M01_AXI_BREADY),
        .s_axi_bresp(axi_smc_M01_AXI_BRESP),
        .s_axi_bvalid(axi_smc_M01_AXI_BVALID),
        .s_axi_rdata(axi_smc_M01_AXI_RDATA),
        .s_axi_rready(axi_smc_M01_AXI_RREADY),
        .s_axi_rresp(axi_smc_M01_AXI_RRESP),
        .s_axi_rvalid(axi_smc_M01_AXI_RVALID),
        .s_axi_wdata(axi_smc_M01_AXI_WDATA),
        .s_axi_wready(axi_smc_M01_AXI_WREADY),
        .s_axi_wstrb(axi_smc_M01_AXI_WSTRB),
        .s_axi_wvalid(axi_smc_M01_AXI_WVALID),
        .spi_initialized_ps(m3_adc_spi_ch0_bridge_0_spi_initialized_ps));
  design_1_v4_reset_domains_phase4c_0_0 v4_reset_domains_phase4c_0
       (.adc_clk(m3_adc_spi_ch0_bridge_0_ch0_clk),
        .adc_control_resetn(v4_reset_domains_phase4c_0_adc_control_resetn),
        .frontend_ready(m3_adc_spi_ch0_bridge_0_frontend_ready),
        .ps_clk(processing_system7_0_FCLK_CLK0),
        .ps_control_resetn(v4_reset_domains_phase4c_0_ps_control_resetn),
        .ps_peripheral_aresetn(rst_ps7_0_50M_peripheral_aresetn));
  design_1_v4_slot_gate_0_0 v4_slot_gate_0
       (.frame_ready(v4_pingpong_0_frame_ready),
        .sink_slot_free(v4_slot_gate_0_sink_slot_free));
  design_1_vdif_packetizer_0_0 vdif_packetizer_0
       (.adc_in_TDATA(v4_periodic_ch0_0_m_axis_tdata),
        .adc_in_TREADY(vdif_packetizer_0_adc_in_TREADY),
        .adc_in_TVALID(cal9_stream_isolation_0_adc_v_o),
        .ap_clk(m3_adc_spi_ch0_bridge_0_ch0_clk),
        .ap_rst_n(cal9_hls_sync_reset_0_hls_resetn),
        .packet_out_TDATA(vdif_packetizer_0_packet_out_TDATA),
        .packet_out_TLAST(vdif_packetizer_0_packet_out_TLAST),
        .packet_out_TKEEP(packet_keep),
        .packet_out_TSTRB(packet_strb),
        .packet_out_TREADY(cal9_stream_isolation_0_pkt_r_o),
        .packet_out_TVALID(vdif_packetizer_0_packet_out_TVALID),
        .pps_in_TDATA(m25_pps_once_0_m_axis_tdata),
        .pps_in_TREADY(vdif_packetizer_0_pps_in_TREADY),
        .pps_in_TVALID(cal9_stream_isolation_0_pps_v_o));

reg psclk=0, adcclk=0, resetn=0, ready=0, normal=0, pattern=0, initialized=0;
reg [13:0] raw=0;
always #10 psclk=~psclk;
always #4 adcclk=~adcclk;
always @(negedge adcclk) raw <= raw + 14'd73;
assign processing_system7_0_FCLK_CLK0=psclk;
assign m3_adc_spi_ch0_bridge_0_ch0_clk=adcclk;
assign rst_ps7_0_50M_peripheral_aresetn=resetn;
assign m3_adc_spi_ch0_bridge_0_frontend_ready=ready;
assign m3_adc_spi_ch0_bridge_0_ch0_raw=raw;
assign m3_adc_spi_ch0_bridge_0_normal_ready_ps=normal;
assign m3_adc_spi_ch0_bridge_0_pattern_active_ps=pattern;
assign m3_adc_spi_ch0_bridge_0_spi_initialized_ps=initialized;
reg [11:0] aw=0, ar=0;
reg [31:0] wd=0;
reg av=0,wv=0,br=0,arv=0,rr=0;
assign axi_smc_M01_AXI_AWADDR=aw;
assign axi_smc_M01_AXI_AWPROT=0;
assign axi_smc_M01_AXI_AWVALID=av;
assign axi_smc_M01_AXI_WDATA=wd;
assign axi_smc_M01_AXI_WSTRB=4'hf;
assign axi_smc_M01_AXI_WVALID=wv;
assign axi_smc_M01_AXI_BREADY=br;
assign axi_smc_M01_AXI_ARADDR=ar;
assign axi_smc_M01_AXI_ARPROT=0;
assign axi_smc_M01_AXI_ARVALID=arv;
assign axi_smc_M01_AXI_RREADY=rr;
task automatic ck(input logic ok,input string msg);
 if(ok!==1'b1) $fatal(1,"CHECK_FAILED: %s",msg);
endtask
task automatic wr(input [11:0] addr,input [31:0] data,input [1:0] response);
 bit ad,dd; ad=0;dd=0;
 @(negedge psclk); aw=addr;wd=data;av=1;wv=1;br=0;
 while(!ad || !dd) begin
  @(posedge psclk); if(av&&axi_smc_M01_AXI_AWREADY) ad=1; if(wv&&axi_smc_M01_AXI_WREADY) dd=1;
  @(negedge psclk); if(ad) av=0; if(dd) wv=0;
 end
 while(axi_smc_M01_AXI_BVALID!==1'b1) @(negedge psclk);
 ck(axi_smc_M01_AXI_BRESP===response,$sformatf("AXI write response addr=%h data=%h got=%b",addr,data,axi_smc_M01_AXI_BRESP));
 br=1; @(negedge psclk);br=0;
endtask
task automatic rd(input [11:0] addr,output reg [31:0] value);
 @(negedge psclk);ar=addr;arv=1;rr=0;
 do @(posedge psclk); while(axi_smc_M01_AXI_ARREADY!==1'b1);
 @(negedge psclk);arv=0;
 while(axi_smc_M01_AXI_RVALID!==1'b1) @(negedge psclk);
 ck(axi_smc_M01_AXI_RRESP===0,"AXI read response");value=axi_smc_M01_AXI_RDATA;rr=1;
 @(negedge psclk);rr=0;
endtask
task automatic snapshot;
 reg [31:0] v;
 wr(12'h00c,1,0); do rd(12'h030,v); while(v[0]!==1'b1);
endtask
task automatic control(input bit start);
 reg [31:0] v;
 wr(12'h050,start?1:2,0);do rd(12'h054,v);while(v[1]!==1'b1 || v[0]!==1'b0);
 ck(v[2]===1'b1,"capture accepted");
endtask
task automatic ack(input [31:0] bank,seq,epoch,input bit accepted);
 reg [31:0] v;
 wr(12'h010,seq,0);wr(12'h014,bank,0);wr(12'h040,epoch,0);wr(12'h00c,2,0);
 do rd(12'h030,v);while(v[1]!==1'b1);rd(12'h028,v);ck(v==accepted,"ACK result");
endtask
// Independent raw reference and persistent BRAM model. Counters are test-only.
reg [13:0] expected_raw[0:1023];
reg [31:0] memory[0:1023];
integer cycles=0,start_cycle=0,captures=0,raw_count=0,raw_verified=0;
integer writes=0,frames=0,bank,wi,j,transfers=0,total_writes=0;
integer before_outage_writes,settled_writes;
integer expected_bank=0, expected_sequence=0;
integer stall_header=0,stall_payload=0,stall_last=0,stall_total=0;
reg abort_at_last=0,was_stalled=0;
reg collecting=0,score_enable=0;
reg [36:0] held_packet;
reg [3:0] held_strb;
reg [15:0] prng=16'hace1;
// Test-only transparent transfer gate. Both sides agree on every handshake.
// Negedge + 1ns avoids races with stimulus and score reset tasks.
always @(negedge adcclk) begin
 #1;
 if (!score_enable || !resetn || !ready) allow_transfer=1;
 else begin
  prng={prng[14:0],prng[15]^prng[13]^prng[12]^prng[10]};
  if ((transfers==0 && stall_header<8) || (transfers==16 && stall_payload<8) ||
      (transfers==263 && (stall_last<8 || abort_at_last))) allow_transfer=0;
  else allow_transfer=(prng[2:0]!=3'b000 && prng[2:0]!=3'b001);
 end
end
always @(posedge adcclk) begin
 if (!score_enable || !resetn || !ready || !cal9_hls_sync_reset_0_stream_enable) was_stalled=0;
 else begin
  if(was_stalled) begin
   ck(vdif_packetizer_0_packet_out_TVALID===1'b1,"TVALID dropped while stalled");
   ck({vdif_packetizer_0_packet_out_TDATA,vdif_packetizer_0_packet_out_TLAST,packet_keep}===held_packet && packet_strb===held_strb,"packet changed while stalled");
  end
  was_stalled=vdif_packetizer_0_packet_out_TVALID && !cal9_stream_isolation_0_pkt_r_o;
  if(was_stalled) begin
   held_packet={vdif_packetizer_0_packet_out_TDATA,vdif_packetizer_0_packet_out_TLAST,packet_keep};held_strb=packet_strb;
   stall_total=stall_total+1;
   if(transfers==0) stall_header=stall_header+1;
   if(transfers==16) stall_payload=stall_payload+1;
   if(transfers==263) stall_last=stall_last+1;
  end
 end
end
reg [31:0] expected_word;
wire [1:0] published=v4_pingpong_0_frame_ready;
`define BUF v4_periodic_ch0_0.inst.u_verified_core.u_frame_buffer
always @(posedge adcclk) begin
 cycles=cycles+1;
 if(score_enable && resetn && ready) begin
  if(axis_bram_writer_0_packet_done) begin
   ck(!collecting && captures==0,"unexpected capture start");
   start_cycle=cycles;raw_count=0;collecting=1;captures=captures+1;
  end else if(collecting && ((cycles-start_cycle-1)%8==0)) begin
   expected_raw[raw_count]=raw;raw_count=raw_count+1;
   if(raw_count==1024) begin
    collecting=0;#1;
    for(j=0;j<1024;j=j+1) ck(`BUF.sample_mem[j]===expected_raw[j],$sformatf("raw14 sample %0d",j));
    raw_verified=raw_verified+1;
   end
  end
 end
end
always @(posedge adcclk) begin
 if(cal9_stream_isolation_0_pkt_v_o && Net) begin
  ck(score_enable && resetn && ready,"packet transfer outside active test epoch");
  ck(packet_keep===4'hf && packet_strb===4'hf,"invalid packet TKEEP/TSTRB");
  ck(vdif_packetizer_0_packet_out_TLAST===(transfers==263),"TLAST position");
  transfers=transfers+1;
 end
 // Model real memory writes even at reset assertion; old contents persist.
 if(axis_bram_writer_0_bram_we===1'b1) begin
  bank=axis_bram_writer_0_bram_addr/2048;wi=(axis_bram_writer_0_bram_addr%2048)/4;
  ck(bank>=0 && bank<2 && wi>=0 && wi<264 && axis_bram_writer_0_bram_addr[1:0]==0,"BRAM address");
  memory[bank*512+wi]=axis_bram_writer_0_bram_data;total_writes=total_writes+1;
  if(score_enable && resetn && ready) begin
   ck(published[bank]===0,"overwrite of published bank");
   ck(bank==expected_bank && wi==writes && raw_verified==1,"fresh bank/word order");
   if(wi>=8) begin
    expected_word={(expected_raw[(wi-8)*4+3][13:6]^8'h80),(expected_raw[(wi-8)*4+2][13:6]^8'h80),(expected_raw[(wi-8)*4+1][13:6]^8'h80),(expected_raw[(wi-8)*4][13:6]^8'h80)};
    ck(axis_bram_writer_0_bram_data===expected_word,$sformatf("VDIF payload word=%0d expected=%h actual=%h",wi,expected_word,axis_bram_writer_0_bram_data));
   end
   writes=writes+1;if(wi==263) frames=frames+1;
  end
 end
end
// A bank must not become visible during an interrupted epoch.
always @(negedge adcclk) begin
 if($time>100 && !score_enable && v4_reset_domains_phase4c_0_adc_control_resetn===0 && cal9_hls_sync_reset_0_hls_resetn===0)
  ck(published===0,"published bank while reset held");
end
reg [31:0] value,epoch0,epoch1,epoch2,seq0;
task automatic clear_score;
 captures=0;raw_count=0;raw_verified=0;collecting=0;writes=0;frames=0;transfers=0;stall_header=0;stall_payload=0;stall_last=0;stall_total=0;was_stalled=0;
endtask
task automatic wait_online;
 reg [31:0] v;
 do rd(12'h034,v);while(v[0]!==1'b1);
 wait(ch0_oneshot_gate_0_capture_enable===1'b1);
 ck(published===0,"bank ready before new START");
endtask
task automatic boot_cal;
 @(negedge psclk);initialized=1;pattern=1;normal=0;
 wr(12'h044,32'h43414c45,0);
 @(negedge adcclk);pattern=0;normal=1;ready=1;
 wait_online();
endtask
task automatic start_new;
 @(negedge adcclk);clear_score();score_enable=1;
 wr(12'h04c,125000,0);control(1);
endtask
task automatic verify_fresh(input string label_name);
 integer base;
 base=expected_bank*512;
 wait(published===(2'b01 << expected_bank));@(negedge adcclk);
 ck(captures==1 && raw_verified==1 && frames==1 && writes==264 && transfers==264,"fresh full frame counters");
 ck(memory[base]===32'h0 && memory[base+1]===(32'h34000000+expected_sequence) && memory[base+2]===32'h20000084 && memory[base+3]===32'h1c005342,"fresh VDIF header");
 for(integer h=4;h<8;h=h+1) ck(memory[base+h]===0,"fresh extended header");
 ck(malformed_frames===0,"malformed frame counter");
 ck(stall_header>=8 && stall_payload>=8 && stall_last>=8,"directed stall coverage");
 control(0);snapshot();rd(12'h018,value);ck(value==(1<<expected_bank),"fresh bank via AXI");
 rd(12'h024,value);ck(value==expected_sequence+1,"completed frame count");
 rd(expected_bank==0?12'h01c:12'h020,seq0);ck(seq0==expected_sequence,"bank sequence");
 $display("STALLED_FRAME_PASS case=%s bank=%0d seq=%0d raw=1024 words=264 stalls=%0d header=%0d payload=%0d final=%0d",label_name,expected_bank,expected_sequence,stall_total,stall_header,stall_payload,stall_last);
endtask
task automatic settled_outage;
 repeat(32) @(negedge adcclk);
 ck(published===0 && v4_pingpong_scalar_0_completed_frames===0,"reset invalidation");
 ck(cal9_hls_sync_reset_0_hls_resetn===0 && cal9_hls_sync_reset_0_stream_enable===0,"reset/stream isolation");
 settled_writes=total_writes;
 repeat(32) @(negedge adcclk);
 ck(total_writes==settled_writes && published===0,"no writes/publication while reset settled");
 $display("RESET_BOUNDARY_WRITES count=%0d",settled_writes-before_outage_writes);
endtask
initial begin
 repeat(10) @(negedge psclk);resetn=1;
 rd(0,value);ck(value===32'h56344332,"magic");boot_cal();rd(12'h038,epoch0);
 // Three consecutive valid acquisitions without resetting the hardware.
 for(integer f=0;f<3;f=f+1) begin
  expected_bank=f%2;expected_sequence=f;
  start_new();verify_fresh("bank_reuse");
  ack(expected_bank,seq0,epoch0,1);ck(published===0,"ACK releases bank");
  wait(v4_periodic_ch0_0_scheduler_idle===1'b1);
  @(negedge adcclk);score_enable=0;
 end
 $display("THREE_STALLED_FRAMES_BANK_REUSE_PASS");
 // Fourth frame: deliberately stall its last word, then reset before acceptance.
 expected_bank=1;expected_sequence=3;abort_at_last=1;
 start_new();wait(stall_last>=8);@(negedge adcclk);
 ck(transfers==263 && writes==263 && frames==0 && published===0 && vdif_packetizer_0_packet_out_TVALID===1 && vdif_packetizer_0_packet_out_TLAST===1,"stalled last word not yet accepted");
 $display("STALLED_LAST_WORD_RESET_REACHED transfers=%0d writes=%0d",transfers,writes);
 score_enable=0;before_outage_writes=total_writes;resetn=0;
 settled_outage();
 @(negedge adcclk);ready=0;normal=0;initialized=0;pattern=0;abort_at_last=0;
 $display("STALLED_PARTIAL_FRAME_INVALIDATED");
 @(negedge psclk);resetn=1;rd(0,value);ck(value===32'h56344332,"AXI reset recovery");
 rd(12'h038,epoch2);ck(epoch2===0,"PS reset epoch restarts at zero");
 boot_cal();expected_bank=0;expected_sequence=0;start_new();verify_fresh("reset_recovery");
 ack(0,seq0,epoch2,1);ck(published===0,"recovery ACK");
 repeat(126000) @(negedge adcclk);
 ck(captures==1 && writes==264 && frames==1 && published===0,"no new frame after STOP");
 $display("STALLED_RESET_RECOVERY_ACK_STOP_PASS");
 $display("CAL10_PHASE9C6D_FIX1_BACKPRESSURE_MODEL_PASS");$finish;
end
initial begin #16000000;$fatal(1,"GLOBAL_TIMEOUT");end
endmodule

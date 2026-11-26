`timescale 1ns/1ps
module tb_cal10_p96b;
  wire Net;
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
        .frame_ready(v4_pingpong_0_frame_ready),
        .in_last(vdif_packetizer_0_packet_out_TLAST),
        .in_valid(cal9_stream_isolation_0_pkt_v_o),
        .in_word(vdif_packetizer_0_packet_out_TDATA),
        .out_ready(Net),
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
// Independent sample reference: first sample at next edge after start, then every eighth edge.
reg [13:0] expected_raw[0:1][0:1023];
reg [31:0] memory[0:1023];
integer cycles=0, start_cycle=0, captures=0, raw_count=0, frames=0, writes=0, bank,wi,j;
reg collecting=0;
reg [31:0] expected_word;
wire [1:0] published=v4_pingpong_0_frame_ready;
`define BUF v4_periodic_ch0_0.inst.u_verified_core.u_frame_buffer
always @(posedge adcclk) begin
 cycles=cycles+1;
 if(resetn && ready) begin
  if(axis_bram_writer_0_packet_done) begin
   ck(!collecting && captures<2,"unexpected capture start");start_cycle=cycles;raw_count=0;collecting=1;captures=captures+1;
  end else if(collecting && ((cycles-start_cycle-1)%8==0)) begin
   expected_raw[captures-1][raw_count]=raw;
   raw_count=raw_count+1;
   if(raw_count==1024) begin
    collecting=0;
    #1;
    for(j=0;j<1024;j=j+1) ck(`BUF.sample_mem[j]===expected_raw[captures-1][j],$sformatf("raw14 sample %0d",j));
    $display("RAW14_D8_FRAME_PASS capture=%0d",captures);
   end
  end
 end
end
// Model the synchronous BRAM Port A writes, retaining memory across reset.
always @(posedge adcclk) begin
 if(resetn && axis_bram_writer_0_bram_we) begin
  bank=axis_bram_writer_0_bram_addr/2048;wi=(axis_bram_writer_0_bram_addr%2048)/4;
  ck(bank>=0 && bank<2 && wi<264 && axis_bram_writer_0_bram_addr[1:0]==0,"BRAM address");
  ck(published[bank]===0,"overwrite of published bank");
  ck(bank==frames && wi==writes%264,"bank and word order");
  if(wi>=8) begin
   expected_word={ (expected_raw[frames][(wi-8)*4+3][13:6]^8'h80), (expected_raw[frames][(wi-8)*4+2][13:6]^8'h80), (expected_raw[frames][(wi-8)*4+1][13:6]^8'h80), (expected_raw[frames][(wi-8)*4][13:6]^8'h80)};
   ck(axis_bram_writer_0_bram_data===expected_word,$sformatf("VDIF payload bank=%0d word=%0d expected=%h actual=%h",bank,wi,expected_word,axis_bram_writer_0_bram_data));
  end
  memory[bank*512+wi]=axis_bram_writer_0_bram_data;writes=writes+1;
  if(wi==263) begin frames=frames+1;$display("VDIF_PAYLOAD_256_WORDS_PASS bank=%0d",bank);end
 end
end
reg [31:0] value, epoch, seq0, seq1, count0;
initial begin
 repeat(10) @(negedge psclk);resetn=1;
 rd(0,value);ck(value===32'h56344332,"magic");
 wr(12'h050,1,2); // offline START rejected
 @(negedge psclk);initialized=1;pattern=1;
 wr(12'h044,32'h43414c45,0);
 @(negedge psclk);pattern=0;normal=1;ready=1;
 do rd(12'h034,value);while(value[0]!==1'b1);
 wait(ch0_oneshot_gate_0_capture_enable===1'b1);
 wr(12'h04c,12500,0);control(1);
 wait(published===2'b11);@(negedge adcclk);
 ck(frames==2 && writes==528 && captures==2,"exact two complete frames");
 // The 123-bit signed header is sign-extended to 125 bits, then cast unsigned
 // and zero-extended to 256 bits. Bit 122=1 extends into bits 123 and 124.
 // Therefore emitted word 3 is expected to be 0x1c005342, not 0x04005342.
 // Print all actual header words BEFORE any assertions, including on failure.
 for(integer b=0;b<2;b=b+1) begin
  for(integer h=0;h<8;h=h+1)
   $display("OBSERVED_VDIF_HEADER bank=%0d word=%0d value=%08h",b,h,memory[b*512+h]);
  $display("OBSERVED_VDIF_SAMPLE_WIDTH bank=%0d bits=%0d",b, {27'd0,memory[b*512+3][30:26]}+32'd1);
 end
 for(integer b=0;b<2;b=b+1) begin
  ck(memory[b*512]===32'h00000000,"header seconds");
  ck(memory[b*512+1]===32'h34000000+b,"header epoch and frame number");
  ck(memory[b*512+2]===32'h20000084,"header length");
  ck(memory[b*512+3]===32'h1c005342,$sformatf("emitted header word3 bank=%0d expected=1c005342 actual=%08h",b,memory[b*512+3]));
  ck(memory[b*512+3][30:26]===5'd7,"VDIF 8-bit sample-width metadata");
  for(integer h=4;h<8;h=h+1) ck(memory[b*512+h]===0,"extended header");
 end
 $display("VDIF_HEADER_WORD3_1C005342_8BIT_FIELD_PASS");
 $display("TWO_VDIF_HEADERS_AND_PAYLOADS_PASS");
 repeat(26000) @(negedge adcclk);
 ck(captures==2 && writes==528,"both banks full no overwrite");
 snapshot();rd(12'h018,value);ck(value==3,"both banks ready via AXI");rd(12'h064,value);ck(value>=2,"skipped windows while full");
 rd(12'h01c,seq0);rd(12'h020,seq1);ck(seq0==0&&seq1==1,"bank sequence");rd(12'h038,epoch);
 $display("BOTH_BANKS_FULL_AND_SKIP_PASS");
 control(0);snapshot();rd(12'h054,value);ck(value[3]===0,"STOP active run cleared");
 wr(12'h010,seq0,0);wr(12'h014,0,0);wr(12'h040,epoch+1,0);wr(12'h00c,2,2);
 ck(published===3,"wrong epoch must not free bank");
 ack(0,seq0+7,epoch,0);ck(published===3,"wrong sequence must not free bank");
 ack(0,seq0,epoch,1);ck(published===2,"bank0 released only");
 ack(1,seq1,epoch,1);ck(published===0,"bank1 released");
 repeat(13000) @(negedge adcclk);ck(captures==2&&writes==528,"no capture after STOP");
 snapshot();rd(12'h018,value);ck(value==0,"PS sees no ready bank");rd(12'h024,value);ck(value==2,"completed frames");
 $display("AXI_EPOCH_SEQUENCE_ACK_STOP_PASS");
 $display("CAL10_PHASE9C6B_FIX1_INTEGRATION_NORMAL_MODEL_PASS");$finish;
end
initial begin #2000000;$fatal(1,"GLOBAL_TIMEOUT");end
endmodule


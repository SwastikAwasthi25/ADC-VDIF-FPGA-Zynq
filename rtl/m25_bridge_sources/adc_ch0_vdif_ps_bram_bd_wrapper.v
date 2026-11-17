module adc_ch0_vdif_ps_bram_bd_wrapper (
    input  wire        adc_clk0_p,
    input  wire        adc_clk0_n,
    input  wire        adc_clk1_p,
    input  wire        adc_clk1_n,
    input  wire        startup_resetn,
    input  wire [27:0] adc_data_pins,

    (* X_INTERFACE_IGNORE = "true" *) output wire [7:0] m_axis_tdata,
    (* X_INTERFACE_IGNORE = "true" *) output wire m_axis_tvalid,
    (* X_INTERFACE_IGNORE = "true" *) output wire m_axis_tready,

    output wire        capture_done,
    output wire        replay_done,
    output wire [10:0] sample_count,
    output wire        frontend_ready,

    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 bram_write_clk CLK", X_INTERFACE_PARAMETER = "FREQ_HZ 125000000" *) output wire bram_write_clk,
    output wire [31:0] bram_write_addr,
    output wire [31:0] bram_write_data,
    output wire        bram_write_en,
    output wire        packet_done
);

adc_ch0_vdif_ps_bram_top u_core (
    .adc_clk0_p      (adc_clk0_p),
    .adc_clk0_n      (adc_clk0_n),
    .adc_clk1_p      (adc_clk1_p),
    .adc_clk1_n      (adc_clk1_n),
    .startup_resetn  (startup_resetn),
    .adc_data_pins   (adc_data_pins),

    .m_axis_tdata    (m_axis_tdata),
    .m_axis_tvalid   (m_axis_tvalid),
    .m_axis_tready   (m_axis_tready),

    .capture_done    (capture_done),
    .replay_done     (replay_done),
    .sample_count    (sample_count),
    .frontend_ready  (frontend_ready),

    .bram_write_clk  (bram_write_clk),
    .bram_write_addr (bram_write_addr),
    .bram_write_data (bram_write_data),
    .bram_write_en   (bram_write_en),
    .packet_done     (packet_done)
);

endmodule


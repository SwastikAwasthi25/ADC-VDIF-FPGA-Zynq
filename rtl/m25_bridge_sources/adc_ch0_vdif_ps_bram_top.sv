`timescale 1ns / 1ps

module adc_ch0_vdif_ps_bram_top (
    input  wire adc_clk0_p,
    input  wire adc_clk0_n,
    input  wire adc_clk1_p,
    input  wire adc_clk1_n,
    input  wire startup_resetn,
    input  wire [3:0][6:0] adc_data_pins,

    output wire [7:0] m_axis_tdata,
    output wire       m_axis_tvalid,
    output wire       m_axis_tready,

    output wire       capture_done,
    output wire       replay_done,
    output wire [10:0] sample_count,
    output wire       frontend_ready,
    output wire        bram_write_clk,
    output wire [31:0] bram_write_addr,
    output wire [31:0] bram_write_data,
    output wire        bram_write_en,
    output wire       packet_done
);

    wire [3:0][13:0] adc_raw;
    wire [3:0][13:0] adc_signed;
    wire [1:0] adc_sample_clk;

    wire clk_ref_200;
    wire clk_01_locked;
    wire clk_23_locked;
    wire idelay_rst;
    wire idelay_ready;
    wire calibration_ready;

    adc_frontend_top u_frontend (
        .adc_clk0_p(adc_clk0_p),
        .adc_clk0_n(adc_clk0_n),
        .adc_clk1_p(adc_clk1_p),
        .adc_clk1_n(adc_clk1_n),
        .startup_resetn(startup_resetn),
        .adc_data_pins(adc_data_pins),
        .adc_raw(adc_raw),
        .adc_signed(adc_signed),
        .adc_sample_clk(adc_sample_clk),
        .clk_ref_200(clk_ref_200),
        .clk_01_locked(clk_01_locked),
        .clk_23_locked(clk_23_locked),
        .idelay_rst(idelay_rst),
        .idelay_ready(idelay_ready),
        .calibration_ready(calibration_ready)
    );

    // CH0 uses ADC sampling clock domain 0.
    wire ch0_clk = adc_sample_clk[0];

    // Reset assertion on loss of clock lock;
    // synchronous release into CH0 clock domain.
    (* ASYNC_REG = "TRUE" *)
    reg [2:0] reset_pipe = 3'b000;

    always @(posedge ch0_clk or negedge clk_01_locked) begin
        if (!clk_01_locked)
            reset_pipe <= 3'b000;
        else
            reset_pipe <= {reset_pipe[1:0], 1'b1};
    end

    wire ch0_rst_n = reset_pipe[2];

    // Synchronize calibration status levels.
    (* ASYNC_REG = "TRUE" *)
    reg [1:0] idelay_sync = 2'b00;

    (* ASYNC_REG = "TRUE" *)
    reg [1:0] cal_sync = 2'b00;

    always @(posedge ch0_clk or negedge ch0_rst_n) begin
        if (!ch0_rst_n) begin
            idelay_sync <= 2'b00;
            cal_sync <= 2'b00;
        end else begin
            idelay_sync <= {idelay_sync[0], idelay_ready};
            cal_sync <= {cal_sync[0], calibration_ready};
        end
    end

    assign frontend_ready =
        ch0_rst_n &&
        idelay_sync[1] &&
        cal_sync[1];

    adc_ch0_live_bridge u_live_bridge (
        .clk(ch0_clk),
        .rst_n(ch0_rst_n),
        .frontend_ready(frontend_ready),
        .adc_raw_ch0(adc_raw[0]),

        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),

        .capture_done(capture_done),
        .replay_done(replay_done),
        .sample_count(sample_count)
    );


    // Single-frame integration: all AXIS components use CH0 clock.
    wire stream_rst_n = ch0_rst_n && frontend_ready;

    // Initial synthetic PPS event for packetizer startup.
    // Not a real UTC/GPS timestamp.
    reg pps_pending = 1'b1;
    wire pps_ready;

    always @(posedge ch0_clk) begin
        if (!stream_rst_n)
            pps_pending <= 1'b1;
        else if (pps_pending && pps_ready)
            pps_pending <= 1'b0;
    end

    wire [31:0] packet_data;
    wire [3:0] packet_keep;
    wire [3:0] packet_strb;
    wire [0:0] packet_last;
    wire packet_valid;
    wire packet_ready;

    design_1_vdif_packetizer_0_0 u_vdif (
        .ap_clk(ch0_clk),
        .ap_rst_n(stream_rst_n),

        .adc_in_TDATA(m_axis_tdata),
        .adc_in_TVALID(m_axis_tvalid),
        .adc_in_TREADY(m_axis_tready),

        .pps_in_TDATA(8'h00),
        .pps_in_TVALID(pps_pending),
        .pps_in_TREADY(pps_ready),

        .packet_out_TDATA(packet_data),
        .packet_out_TKEEP(packet_keep),
        .packet_out_TSTRB(packet_strb),
        .packet_out_TLAST(packet_last),
        .packet_out_TVALID(packet_valid),
        .packet_out_TREADY(packet_ready)
    );

    wire [31:0] writer_addr;
    wire [31:0] writer_data;
    wire writer_we;
    wire writer_done;

    axis_bram_writer #(
        .FRAME_WORDS(264),
        .BRAM_WORDS(512)
    ) u_writer (
        .clk(ch0_clk),
        .rst_n(stream_rst_n),
        .rearm_req(1'b0),

        .s_axis_tdata(packet_data),
        .s_axis_tvalid(packet_valid),
        .s_axis_tlast(packet_last[0]),
        .s_axis_tready(packet_ready),

        .bram_addr(writer_addr),
        .bram_data(writer_data),
        .bram_we(writer_we),
        .packet_done(writer_done)
    );

    // External BRAM Port A interface for Vivado Block Design.
    // Address follows the existing writer's byte-address convention.
    assign bram_write_clk  = ch0_clk;
    assign bram_write_addr = writer_addr;
    assign bram_write_data = writer_data;
    assign bram_write_en   = writer_we;
    // Delay completion visibility so the final registered write
    // has reached the BRAM.
    reg packet_done_d = 1'b0;

    always @(posedge ch0_clk) begin
        if (!stream_rst_n)
            packet_done_d <= 1'b0;
        else
            packet_done_d <= writer_done;
    end

    assign packet_done = packet_done_d;
endmodule



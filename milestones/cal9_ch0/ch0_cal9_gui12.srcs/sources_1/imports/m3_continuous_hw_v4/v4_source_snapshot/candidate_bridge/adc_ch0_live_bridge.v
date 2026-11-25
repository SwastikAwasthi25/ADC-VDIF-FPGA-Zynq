`timescale 1ns / 1ps

module adc_ch0_live_bridge (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        frontend_ready,
    input  wire [13:0] adc_raw_ch0,

    output wire [7:0]  m_axis_tdata,
    output wire        m_axis_tvalid,
    input  wire        m_axis_tready,

    output wire        capture_done,
    output wire        replay_done,
    output wire [10:0] sample_count
);

    // frontend_ready must already be synchronized
    // to the CH0 sample clock.

    wire buffer_rst_n = rst_n && frontend_ready;

    reg started;
    reg start_pulse;

    always @(posedge clk) begin
        if (!buffer_rst_n) begin
            started     <= 1'b0;
            start_pulse <= 1'b0;
        end else begin
            start_pulse <= 1'b0;

            if (!started) begin
                started     <= 1'b1;
                start_pulse <= 1'b1;
            end
        end
    end

    adc_ch0_frame_buffer u_frame_buffer (
        .clk           (clk),
        .rst_n         (buffer_rst_n),
        .start_capture (start_pulse),
        .sample_valid  (frontend_ready),
        .adc_raw_ch0   (adc_raw_ch0),

        .m_axis_tdata  (m_axis_tdata),
        .m_axis_tvalid (m_axis_tvalid),
        .m_axis_tready (m_axis_tready),

        .capture_done  (capture_done),
        .replay_done   (replay_done),
        .sample_count  (sample_count)
    );

endmodule

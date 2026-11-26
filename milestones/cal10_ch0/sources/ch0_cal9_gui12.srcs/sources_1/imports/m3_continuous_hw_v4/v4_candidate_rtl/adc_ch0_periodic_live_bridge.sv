`timescale 1ns / 1ps
// Offline experiment only: re-arms the existing 1024-sample CH0 buffer on
// periodic *eligible* windows. All inputs are synchronous to clk. At real
// integration sink_slot_free must be synchronized to CH0 clock, not PS clock.
// The acquisition gaps are intentional: this is NOT lossless full-rate ADC.
module adc_ch0_periodic_live_bridge #(
    parameter integer PERIOD_CYCLES = 125_000_000
) (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        frontend_ready,
    input  wire        capture_enable,
    input  wire        run_enable_adc,
    input  wire [31:0] period_cycles_adc,
    output wire        scheduler_idle,
    input  wire        sink_slot_free,
    input  wire [13:0] adc_raw_ch0,
    output wire [7:0]  m_axis_tdata,
    output wire        m_axis_tvalid,
    input  wire        m_axis_tready,
    output wire        capture_done,
    output wire        replay_done,
    output wire [10:0] sample_count,
    output reg         start_capture_pulse,
    output reg [31:0] captures_started,
    output reg [31:0] captures_replayed,
    output reg [31:0] skipped_windows
);
    // WAIT -> PULSE -> RUN: PULSE avoids observing stale replay_done from
    // the preceding acquisition before the frame buffer clears that flag.
    localparam [1:0] ST_WAIT = 2'd0, ST_PULSE = 2'd1, ST_RUN = 2'd2;
    localparam integer COUNT_W = 32;
    reg [COUNT_W-1:0] tick_count;
    reg [1:0] state;
    wire period_valid =
        (period_cycles_adc >= 32'd12500) &&
        (period_cycles_adc <= 32'd125000000);

    wire recording_active =
        run_enable_adc && capture_enable && period_valid;

    wire tick = period_valid &&
        (tick_count >= period_cycles_adc - 1);

    assign scheduler_idle = (state == ST_WAIT);
    wire buffer_rst_n = rst_n && frontend_ready;

    wire decimation_valid;

    cal10_decimator_d8 u_decimator (
        .clk(clk),
        .rst_n(rst_n),
        .frontend_ready(frontend_ready),
        .start_capture(start_capture_pulse),
        .sample_valid(decimation_valid)
    );

    adc_ch0_frame_buffer u_frame_buffer (
        .clk(clk),
        .rst_n(buffer_rst_n),
        .start_capture(start_capture_pulse),
        .sample_valid(decimation_valid),
        .adc_raw_ch0(adc_raw_ch0),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .capture_done(capture_done),
        .replay_done(replay_done),
        .sample_count(sample_count)
    );

    always @(posedge clk) begin
        if (!rst_n) begin
            tick_count <= {COUNT_W{1'b0}};
            state <= ST_WAIT;
            start_capture_pulse <= 1'b0;
            captures_started <= 32'd0;
            captures_replayed <= 32'd0;
            skipped_windows <= 32'd0;
        end else if (!frontend_ready) begin
            // Readiness loss invalidates any in-progress raw capture/replay.
            // Keep diagnostic counters; begin new cadence after recovery.
            tick_count <= {COUNT_W{1'b0}};
            state <= ST_WAIT;
            start_capture_pulse <= 1'b0;
        end else begin
            start_capture_pulse <= 1'b0;
            if (!recording_active || tick)
                tick_count <= {COUNT_W{1'b0}};
            else
                tick_count <= tick_count + 1'b1;

            case (state)
                ST_WAIT: begin
                    if (tick && recording_active && sink_slot_free) begin
                        start_capture_pulse <= 1'b1;
                        captures_started <= captures_started + 1'b1;
                        state <= ST_PULSE;
                    end
                end
                ST_PULSE: begin
                    // On this clock, the original buffer sees start_capture=1.
                    // Its latched replay_done is cleared by the same clock.
                    state <= ST_RUN;
                end
                ST_RUN: begin
                    if (replay_done) begin
                        captures_replayed <= captures_replayed + 1'b1;
                        state <= ST_WAIT;
                    end
                end
                default: state <= ST_WAIT;
            endcase
            // One skipped opportunity per period, not one per stalled clock.
            if (tick && recording_active &&
                !(state == ST_WAIT && sink_slot_free))
                skipped_windows <= skipped_windows + 1'b1;
        end
    end
endmodule


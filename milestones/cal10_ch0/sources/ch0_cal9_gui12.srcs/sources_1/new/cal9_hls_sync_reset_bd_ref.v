`timescale 1ns / 1ps

module cal9_hls_sync_reset_bd_ref (
    input  wire adc_clk,
    input  wire adc_control_resetn,
    output wire hls_resetn,
    output wire stream_enable
);

    cal9_hls_sync_reset_candidate_v2 u_verified_adapter (
        .adc_clk(adc_clk),
        .adc_control_resetn(adc_control_resetn),
        .hls_resetn(hls_resetn),
        .stream_enable(stream_enable)
    );

endmodule


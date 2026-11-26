`timescale 1ns/1ps

module cal9_hls_sync_reset_candidate_v2 (
    input wire adc_clk,
    input wire adc_control_resetn,
    output wire hls_resetn,
    output wire stream_enable
);

    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *)
    reg reset_meta = 1'b0;

    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *)
    reg reset_sync = 1'b0;

    always @(posedge adc_clk) begin
        reset_meta <= adc_control_resetn;
        reset_sync <= reset_meta;
    end

    assign hls_resetn = reset_sync;

    assign stream_enable =
        adc_control_resetn && reset_sync;

endmodule
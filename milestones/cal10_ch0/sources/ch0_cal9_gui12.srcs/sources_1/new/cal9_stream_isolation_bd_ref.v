`timescale 1ns / 1ps

module cal9_stream_isolation_bd_ref (
    input  wire stream_enable,

    input  wire adc_v_i,
    output wire adc_v_o,

    input  wire adc_r_i,
    output wire adc_r_o,

    input  wire pps_v_i,
    output wire pps_v_o,

    input  wire pps_r_i,
    output wire pps_r_o,

    input  wire pkt_v_i,
    output wire pkt_v_o,

    input  wire pkt_r_i,
    output wire pkt_r_o
);

    assign adc_v_o = adc_v_i & stream_enable;
    assign adc_r_o = adc_r_i & stream_enable;

    assign pps_v_o = pps_v_i & stream_enable;
    assign pps_r_o = pps_r_i & stream_enable;

    assign pkt_v_o = pkt_v_i & stream_enable;
    assign pkt_r_o = pkt_r_i & stream_enable;

endmodule


`timescale 1ns / 1ps
// BD wrapper only. Verified experimental core remains byte-identical.
module v4_control_reset_bd_ref (
 input wire ps_clk, input wire adc_clk,
 input wire ps_peripheral_aresetn, input wire frontend_ready,
 output wire common_async_resetn,
 output wire ps_control_resetn, output wire adc_control_resetn
);
 v4_control_reset_fabric u_reset_fabric (
   .ps_clk(ps_clk),.adc_clk(adc_clk),
   .ps_peripheral_aresetn(ps_peripheral_aresetn),
   .frontend_ready(frontend_ready),
   .common_async_resetn(common_async_resetn),
   .ps_control_resetn(ps_control_resetn),
   .adc_control_resetn(adc_control_resetn)
 );
endmodule
`timescale 1ns/1ps
// Only exposes unchanged Phase4A experimental RTL to IP Integrator.
module v4_phase4c_reset_bd_ref (
 input wire ps_clk, input wire adc_clk,
 input wire ps_peripheral_aresetn, input wire frontend_ready,
 output wire ps_control_resetn, output wire adc_control_resetn
);
 v4_reset_domains_experimental u_phase4c_reset (
  .ps_clk(ps_clk),.adc_clk(adc_clk),
  .ps_peripheral_aresetn(ps_peripheral_aresetn),.frontend_ready(frontend_ready),
  .ps_control_resetn(ps_control_resetn),.adc_control_resetn(adc_control_resetn)
 );
endmodule
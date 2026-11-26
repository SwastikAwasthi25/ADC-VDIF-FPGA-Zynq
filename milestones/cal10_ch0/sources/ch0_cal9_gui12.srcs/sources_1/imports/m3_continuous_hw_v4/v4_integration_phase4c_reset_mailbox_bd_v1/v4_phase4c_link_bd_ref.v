`timescale 1ns/1ps
// PS-domain link readiness; remains low until BOTH local reset releases.
module v4_phase4c_link_bd_ref (
 input wire ps_clk, input wire ps_peripheral_aresetn,
 input wire ps_control_resetn, input wire adc_control_resetn,
 output wire frontend_online_ps
);
 v4_ps_link_ready_experimental u_phase4c_link (
  .ps_clk(ps_clk),.ps_peripheral_aresetn(ps_peripheral_aresetn),
  .ps_control_resetn(ps_control_resetn),.adc_control_resetn(adc_control_resetn),
  .frontend_online_ps(frontend_online_ps)
 );
endmodule
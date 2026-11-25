`timescale 1ns/1ps
// Experimental dual-domain reset fabric for isolated V4 XSim validation.
// This module is a proposal, NOT yet integrated into the Vivado Block Design.
// Async assertion is common to both domains. Release is independently
// synchronized using three flip-flops in each clock domain.
module v4_control_reset_fabric (
    input  wire ps_clk,
    input  wire adc_clk,
    input  wire ps_peripheral_aresetn,
    input  wire frontend_ready,
    output wire common_async_resetn,
    output wire ps_control_resetn,
    output wire adc_control_resetn
);
    assign common_async_resetn = ps_peripheral_aresetn & frontend_ready;

    (* ASYNC_REG = "TRUE" *) reg [2:0] ps_release_pipe;
    (* ASYNC_REG = "TRUE" *) reg [2:0] adc_release_pipe;

    always @(posedge ps_clk or negedge common_async_resetn) begin
        if (!common_async_resetn)
            ps_release_pipe <= 3'b000;
        else
            ps_release_pipe <= {ps_release_pipe[1:0], 1'b1};
    end

    always @(posedge adc_clk or negedge common_async_resetn) begin
        if (!common_async_resetn)
            adc_release_pipe <= 3'b000;
        else
            adc_release_pipe <= {adc_release_pipe[1:0], 1'b1};
    end

    assign ps_control_resetn = ps_release_pipe[2];
    assign adc_control_resetn = adc_release_pipe[2];
endmodule

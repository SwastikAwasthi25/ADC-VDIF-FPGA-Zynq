`timescale 1ns/1ps

module v4_reset_domains_experimental (
    input  wire ps_clk,
    input  wire adc_clk,

    input  wire ps_peripheral_aresetn,
    input  wire frontend_ready,

    output wire ps_control_resetn,
    output wire adc_control_resetn
);

    // Experimental common reset assertion.
    // Physical reset-source qualification remains required.

    wire common_resetn;

    assign common_resetn =
        ps_peripheral_aresetn & frontend_ready;

    // Asynchronous assertion.
    // Independent synchronous release in each domain.
    // Reset remains asserted for multiple local clock edges.

    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *)
    reg [3:0] ps_release_pipe;

    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *)
    reg [3:0] adc_release_pipe;

    always @(posedge ps_clk or negedge common_resetn) begin

        if (!common_resetn)
            ps_release_pipe <= 4'b0000;
        else
            ps_release_pipe <= {
                ps_release_pipe[2:0], 1'b1
            };

    end

    always @(posedge adc_clk or negedge common_resetn) begin

        if (!common_resetn)
            adc_release_pipe <= 4'b0000;
        else
            adc_release_pipe <= {
                adc_release_pipe[2:0], 1'b1
            };

    end

    assign ps_control_resetn = ps_release_pipe[3];

    assign adc_control_resetn = adc_release_pipe[3];

endmodule
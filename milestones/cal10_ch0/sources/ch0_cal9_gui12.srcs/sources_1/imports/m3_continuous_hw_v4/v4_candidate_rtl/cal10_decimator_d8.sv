`timescale 1ns / 1ps

module cal10_decimator_d8 (
    input  wire clk,
    input  wire rst_n,
    input  wire frontend_ready,
    input  wire start_capture,

    output wire sample_valid
);

    reg [2:0] phase;

    always @(posedge clk) begin
        if (!rst_n || !frontend_ready)
            phase <= 3'd0;
        else if (start_capture)
            phase <= 3'd0;
        else
            phase <= phase + 3'd1;
    end

    assign sample_valid =
        rst_n &&
        frontend_ready &&
        !start_capture &&
        (phase == 3'd0);

endmodule

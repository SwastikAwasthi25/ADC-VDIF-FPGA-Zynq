`timescale 1ns/1ps
// CAL9 periodic CH0 diagnostic capture gate.
// All signals live in the same adc_clk/reset domain as the original
// adc_ch0_periodic_live_bridge. No clock-domain crossing introduced.
// Repeated captures are allowed within a live reset epoch. Any frontend loss
// while armed disables acquisition until the reset domain is restarted.
// Existing periodic core completes an in-flight frame even after enable drops.
module ch0_oneshot_capture_gate #(
    parameter integer READY_STABLE_CYCLES = 1024
)(
    input  wire clk,
    input  wire rst_n,
    input  wire frontend_ready,
    input  wire [31:0] captures_started,
    output wire capture_enable,
    output wire armed_o,
    output wire fault_o
);
    localparam integer COUNT_W = (READY_STABLE_CYCLES <= 2) ? 1 : $clog2(READY_STABLE_CYCLES+1);
    localparam [1:0] WAIT_READY=2'd0, ARMED=2'd1,
                     LOCKED=2'd2, FAULT=2'd3;
    reg [1:0] state;
    reg [COUNT_W-1:0] ready_count;
    assign capture_enable = rst_n && frontend_ready &&
        (state == ARMED);
    assign armed_o = (state == ARMED);
    assign fault_o = (state == FAULT);
    always @(posedge clk) begin
        if (!rst_n) begin
            state <= WAIT_READY;
            ready_count <= {COUNT_W{1'b0}};
        end else begin
            case (state)
                WAIT_READY: begin
                    if (!frontend_ready) begin
                        ready_count <= {COUNT_W{1'b0}};
                    end else if (captures_started != 32'd0) begin
                        state <= FAULT; // unexpected prior acquisition
                    end else if (ready_count >= READY_STABLE_CYCLES-1) begin
                        state <= ARMED;
                    end else begin
                        ready_count <= ready_count + 1'b1;
                    end
                end
                ARMED: begin
                    if (!frontend_ready) state <= FAULT;
                    // Remain armed for subsequent periodic captures.
                end
                LOCKED: begin
                    // Remain closed even after PS ACK frees the BRAM bank.
                    // A reset creates a new capture/recorder epoch.
                    if (!frontend_ready) state <= FAULT;
                end
                FAULT: state <= FAULT;
                default: state <= FAULT;
            endcase
        end
    end
endmodule

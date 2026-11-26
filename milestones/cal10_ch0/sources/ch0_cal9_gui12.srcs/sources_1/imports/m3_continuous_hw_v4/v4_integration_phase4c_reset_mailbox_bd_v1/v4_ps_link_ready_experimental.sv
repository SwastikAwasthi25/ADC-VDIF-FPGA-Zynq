`timescale 1ns/1ps
// Phase 4B experiment: PS-visible readiness of BOTH independently released
// control clock domains. A purely PS-clock FF output, not an async-reset gate.
// Important: does NOT detect an ADC clock that STOPS AFTER becoming ready.
module v4_ps_link_ready_experimental (
    input wire ps_clk,
    input wire ps_peripheral_aresetn,
    input wire ps_control_resetn,
    input wire adc_control_resetn,
    output reg frontend_online_ps
);
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *) reg adc_ready_meta;
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *) reg adc_ready_sync;

    always @(posedge ps_clk or negedge ps_peripheral_aresetn) begin
        if (!ps_peripheral_aresetn) begin
            adc_ready_meta <= 1'b0;
            adc_ready_sync <= 1'b0;
            frontend_online_ps <= 1'b0;
        end else begin
            adc_ready_meta <= adc_control_resetn;
            adc_ready_sync <= adc_ready_meta;
            frontend_online_ps <= ps_control_resetn && adc_ready_sync;
        end
    end
endmodule

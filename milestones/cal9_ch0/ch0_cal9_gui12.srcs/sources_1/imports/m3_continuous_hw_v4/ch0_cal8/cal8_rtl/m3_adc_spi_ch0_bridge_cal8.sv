// CAL8 ISOLATED CANDIDATE. NOT PHYSICALLY CALIBRATED. NO BOARD AUTHORIZATION.
`timescale 1ns / 1ps
// M3 integration adapter for Red Pitaya STEM_125-14_Z7020_4IN_v1.3.
// CH0 only; preserves all four ADC lanes in the validated frontend.
// This is an untested integration component. Do not program the FPGA
// until complete BD, XDC, CDC, simulation and implementation checks pass.
module m3_adc_spi_ch0_bridge #(
    // M2.5 PS FCLK0 is 50 MHz: 5,000,000 cycles ~100 ms.
    parameter integer SPI_STARTUP_CYCLES = 5_000_000,
    parameter integer NORMAL_SETTLE_CYCLES = 1024
)(
    input  wire        ps_clk_50,
    input  wire        ps_resetn,
    input  wire        adc_clk0_p,
    input  wire        adc_clk0_n,
    input  wire        adc_clk1_p,
    input  wire        adc_clk1_n,
    input  wire [27:0] adc_data_pins,
    output wire        spi_csa_o,
    output wire        spi_csb_o,
    output wire        spi_clk_o,
    output wire        spi_mosi_o,
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 ch0_clk CLK", X_INTERFACE_PARAMETER = "FREQ_HZ 125000000" *) output wire        ch0_clk,
    output wire        ch0_resetn,
    output wire [13:0] ch0_raw,
    output wire        frontend_ready,
    output wire        spi_done,
    input  wire        cal_exit_req_ps,
    output wire        spi_initialized_ps,
    output wire        pattern_active_ps,
    output wire        normal_ready_ps
);
    // Calibration-first ownership: exactly one SPI master drives both chips.
    // The Phase4Q controller was previously simulation-tested in isolation.
    // Normal-mode recording remains disabled until explicit software exit.
    wire spi_busy_unused;
    phase4q_adc_spi_calibration_ctrl #(
        .STARTUP_CYCLES(SPI_STARTUP_CYCLES),
        .NORMAL_SETTLE_CYCLES(NORMAL_SETTLE_CYCLES)
    ) u_cal_spi (
        .clk_ps_50(ps_clk_50),
        .resetn(ps_resetn),
        .exit_calibration_req_i(cal_exit_req_ps),
        .spi_csa_o(spi_csa_o),
        .spi_csb_o(spi_csb_o),
        .spi_clk_o(spi_clk_o),
        .spi_mosi_o(spi_mosi_o),
        .spi_busy_o(spi_busy_unused),
        .spi_initialized_o(spi_initialized_ps),
        .pattern_active_o(pattern_active_ps),
        .normal_ready_o(normal_ready_ps)
    );
    assign spi_done = spi_initialized_ps;

    // SPI complete -> release ADC frontend reset in the PS FCLK domain.
    (* ASYNC_REG = "TRUE" *) reg [2:0] startup_sync = 3'b000;
    always @(posedge ps_clk_50 or negedge ps_resetn) begin
        if (!ps_resetn || !spi_done)
            startup_sync <= 3'b000;
        else
            startup_sync <= {startup_sync[1:0], 1'b1};
    end
    wire startup_resetn = startup_sync[2];

    wire [3:0][13:0] adc_raw;
    wire [3:0][13:0] adc_signed_unused;
    wire [1:0] adc_sample_clk;
    wire clk_ref_200_unused;
    wire clk_01_locked;
    wire clk_23_locked_unused;
    wire idelay_rst_unused;
    wire idelay_ready;
    wire calibration_ready;

    adc_frontend_top u_frontend (
        .adc_clk0_p      (adc_clk0_p),
        .adc_clk0_n      (adc_clk0_n),
        .adc_clk1_p      (adc_clk1_p),
        .adc_clk1_n      (adc_clk1_n),
        .startup_resetn  (startup_resetn),
        .adc_data_pins   (adc_data_pins),
        .adc_raw         (adc_raw),
        .adc_signed      (adc_signed_unused),
        .adc_sample_clk  (adc_sample_clk),
        .clk_ref_200     (clk_ref_200_unused),
        .clk_01_locked   (clk_01_locked),
        .clk_23_locked   (clk_23_locked_unused),
        .idelay_rst      (idelay_rst_unused),
        .idelay_ready    (idelay_ready),
        .calibration_ready(calibration_ready)
    );

    // CH0 and CH1 are clocked by ADC sampling domain 0.
    assign ch0_clk = adc_sample_clk[0];
    assign ch0_raw = adc_raw[0];

    // Same lock/reset and readiness synchronization pattern used by the
    // hardware-tested ADC ILA sandbox (one domain only, CH0).
    (* ASYNC_REG = "TRUE" *) reg [2:0] reset_pipe = 3'b000;
    always @(posedge ch0_clk or negedge clk_01_locked) begin
        if (!clk_01_locked)
            reset_pipe <= 3'b000;
        else
            reset_pipe <= {reset_pipe[1:0], 1'b1};
    end
    assign ch0_resetn = reset_pipe[2];

    (* ASYNC_REG = "TRUE" *) reg [1:0] idelay_sync = 2'b00;
    (* ASYNC_REG = "TRUE" *) reg [1:0] cal_sync    = 2'b00;
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *) reg [1:0] normal_sync = 2'b00;
    always @(posedge ch0_clk or negedge ch0_resetn) begin
        if (!ch0_resetn) begin
            idelay_sync <= 2'b00;
            cal_sync    <= 2'b00;
            normal_sync <= 2'b00;
        end else begin
            idelay_sync <= {idelay_sync[0], idelay_ready};
            cal_sync    <= {cal_sync[0], calibration_ready};
            normal_sync <= {normal_sync[0], normal_ready_ps};
        end
    end
    
reg frontend_ready_q = 1'b0;

always @(posedge ch0_clk) begin
    if (!ch0_resetn)
        frontend_ready_q <= 1'b0;
    else
        frontend_ready_q <= idelay_sync[1] && cal_sync[1] && normal_sync[1];
end

assign frontend_ready = frontend_ready_q;

endmodule

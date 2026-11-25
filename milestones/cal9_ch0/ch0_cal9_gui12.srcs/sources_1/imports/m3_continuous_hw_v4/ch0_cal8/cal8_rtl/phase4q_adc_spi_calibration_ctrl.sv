`timescale 1ns / 1ps
// PHASE 4Q ISOLATED EXPERIMENT - NOT IN THE ACTIVE XPR OR BOARD BITSTREAM.
// Two-phase SPI controller for an LTC2145-family ADC pair:
//   INIT: 0x0100, 0x020D, 0x0302, 0x0428 (enable checkerboard)
//   WAIT: leave checkerboard active so a separately enabled capture checker
//         could observe it (not implemented in this isolated controller).
//   EXIT: 0x0400 (restore normal conversion), wait a configurable guard,
//         then permit NORMAL-mode payload recording.
// IMPORTANT: spi_initialized_o can release the ADC frontend, but MUST NOT be
// used to enable real recording; recording must be gated by normal_ready_o.
// Input exit_calibration_req_i must stay asserted until normal_ready_o.
// External physical timing/settling, CDC, calibration and board signoff remain pending.
module phase4q_adc_spi_calibration_ctrl #(
    parameter integer STARTUP_CYCLES       = 5_000_000, // 100 ms at 50 MHz
    parameter integer NORMAL_SETTLE_CYCLES = 1024      // provisional guard, not ADC datasheet signoff
)(
    input  wire clk_ps_50,
    input  wire resetn,
    input  wire exit_calibration_req_i,
    output wire spi_csa_o,
    output wire spi_csb_o,
    output wire spi_clk_o,
    output wire spi_mosi_o,
    output wire spi_busy_o,
    output reg  spi_initialized_o,
    output reg  pattern_active_o,
    output reg  normal_ready_o
);
    localparam [2:0] ST_DELAY     = 3'd0,
                     ST_START     = 3'd1,
                     ST_WAIT_BUSY = 3'd2,
                     ST_WAIT_IDLE = 3'd3,
                     ST_CAL_HOLD  = 3'd4,
                     ST_SETTLE    = 3'd5,
                     ST_DONE      = 3'd6;

    reg [2:0] state;
    reg [2:0] command_index;
    reg [31:0] delay_count;
    reg [31:0] settle_count;
    reg [15:0] spi_address;
    reg [15:0] spi_data;
    wire spi_busy;
    wire spi_start = (state == ST_START);
    wire [0:0] spi_cs;
    wire spi_mosi_unused;

    assign spi_csa_o = spi_cs[0];
    assign spi_csb_o = spi_cs[0];
    assign spi_busy_o = spi_busy;

    always @(*) begin
        spi_address = 16'h0001;
        spi_data = 16'h0000;
        case (command_index)
            3'd0: begin spi_address = 16'h0001; spi_data = 16'h0000; end
            3'd1: begin spi_address = 16'h0002; spi_data = 16'h000D; end
            3'd2: begin spi_address = 16'h0003; spi_data = 16'h0002; end
            3'd3: begin spi_address = 16'h0004; spi_data = 16'h0028; end
            3'd4: begin spi_address = 16'h0004; spi_data = 16'h0000; end
            default: begin spi_address = 16'h0001; spi_data = 16'h0000; end
        endcase
    end

    // This request may originate outside the PS clock domain when integrated.
    // Two-stage metastability synchronizer; the caller MUST hold the level.
    (* ASYNC_REG = "TRUE" *) reg [1:0] exit_sync = 2'b00;
    always @(posedge clk_ps_50 or negedge resetn) begin
        if (!resetn) exit_sync <= 2'b00;
        else         exit_sync <= {exit_sync[0], exit_calibration_req_i};
    end

    always @(posedge clk_ps_50 or negedge resetn) begin
        if (!resetn) begin
            state              <= ST_DELAY;
            command_index      <= 3'd0;
            delay_count        <= 32'd0;
            settle_count       <= 32'd0;
            spi_initialized_o  <= 1'b0;
            pattern_active_o   <= 1'b0;
            normal_ready_o     <= 1'b0;
        end else begin
            case (state)
                ST_DELAY: begin
                    if (delay_count >= STARTUP_CYCLES - 1) state <= ST_START;
                    else delay_count <= delay_count + 1'b1;
                end
                ST_START: state <= ST_WAIT_BUSY;
                ST_WAIT_BUSY: if (spi_busy) state <= ST_WAIT_IDLE;
                ST_WAIT_IDLE: begin
                    if (!spi_busy) begin
                        if (command_index < 3'd3) begin
                            command_index <= command_index + 1'b1;
                            state <= ST_START;
                        end else if (command_index == 3'd3) begin
                            // Fourth SPI transaction has completed. ADC clocks
                            // may start; no real-recording enable is asserted.
                            spi_initialized_o <= 1'b1;
                            pattern_active_o <= 1'b1;
                            state <= ST_CAL_HOLD;
                        end else begin
                            // Fifth transaction 0x0400 completed; start guard.
                            pattern_active_o <= 1'b0;
                            settle_count <= 32'd0;
                            state <= ST_SETTLE;
                        end
                    end
                end
                ST_CAL_HOLD: begin
                    // Explicitly hold pattern until a synchronized release.
                    if (exit_sync[1]) begin
                        command_index <= 3'd4;
                        state <= ST_START;
                    end
                end
                ST_SETTLE: begin
                    if (settle_count >= NORMAL_SETTLE_CYCLES - 1) begin
                        normal_ready_o <= 1'b1;
                        state <= ST_DONE;
                    end else settle_count <= settle_count + 1'b1;
                end
                ST_DONE: state <= ST_DONE;
                default: state <= ST_DELAY;
            endcase
        end
    end

    spi_master #(.RST_ACT_LVL(0), .NUM_OF_CS(1)) u_spi_master (
        .clk_i(clk_ps_50), .rst_i(resetn),
        .spi_cs_o(spi_cs), .spi_clk_o(spi_clk_o),
        .spi_miso_i(1'b0), .spi_mosi_t(spi_mosi_unused),
        .spi_mosi_o(spi_mosi_o),
        .spi_start_i(spi_start),
        .dat_wr_h_i(spi_address), .dat_wr_l_i(spi_data), .dat_rd_l_o(),
        .cfg_rw_i(1'b0), .cfg_cs_act_i(1'b1),
        .cfg_h_lng_i(5'd8), .cfg_l_lng_i(5'd8),
        .cfg_clk_presc_i(8'd10),
        .cfg_clk_wr_edg_i(1'b1), .cfg_clk_rd_edg_i(1'b1),
        .cfg_clk_idle_i(1'b1), .sts_spi_busy_o(spi_busy)
    );
endmodule

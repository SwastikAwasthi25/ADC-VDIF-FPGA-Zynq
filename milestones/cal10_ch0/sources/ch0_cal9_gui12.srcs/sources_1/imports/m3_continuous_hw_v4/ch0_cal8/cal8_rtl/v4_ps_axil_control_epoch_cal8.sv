// CAL8 ISOLATED EXPERIMENTAL REGISTER ABI VERSION 0x00010002.
`timescale 1ns / 1ps
// V4 EXPERIMENTAL PS-clock AXI4-Lite control peripheral.
// Does NOT replace the AXI BRAM Controller (separate 4 KiB address window).
// One outstanding AXI write response, one outstanding AXI read response.
// AW and W channels accepted independently. Full word strobes required for writes.
// No burst/AXI-full behavior. Only status and ACK commands reach the CDC module.
// STATUS snapshot values stay coherent between completed snapshot transactions.
// All status/ACK controls operate in the PS clock domain.
module v4_ps_axil_control_epoch (
    input  wire        s_axi_aclk,
    input  wire        rst_n, // PS peripheral reset, independent of ADC frontend
    input  wire        frontend_online, // reset fabric PS-domain synchronized release
    input  wire [11:0] s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output wire        s_axi_awready,
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output wire        s_axi_wready,
    output reg  [1:0]  s_axi_bresp,
    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,
    input  wire [11:0] s_axi_araddr,
    input  wire        s_axi_arvalid,
    output wire        s_axi_arready,
    output reg  [31:0] s_axi_rdata,
    output reg  [1:0]  s_axi_rresp,
    output reg         s_axi_rvalid,
    input  wire        s_axi_rready,

    // Connect directly to v4_frame_mailbox_cdc PS-side ports.
    output reg         ps_status_req,
    input  wire        ps_status_busy,
    input  wire        ps_status_valid,
    input  wire [1:0]  ps_frame_ready,
    input  wire [31:0] ps_bank0_sequence,
    input  wire [31:0] ps_bank1_sequence,
    input  wire [31:0] ps_completed_frames,

    input wire [31:0] ps_captures_started,
    input wire [31:0] ps_captures_replayed,
    input wire [31:0] ps_skipped_windows,
    input wire        ps_scheduler_idle,

    input wire        ps_active_run,
    input wire [31:0] ps_active_period,

    output reg        ps_capture_req,
    output reg        ps_capture_enable,
    output reg [31:0] ps_capture_period,

    input wire        ps_capture_busy,
    input wire        ps_capture_done,
    input wire        ps_capture_accepted,
    output reg         ps_ack_req,
    output reg         ps_ack_bank,
    output reg  [31:0] ps_ack_expected_sequence,
    input  wire        ps_ack_busy,
    input  wire        ps_ack_done,
    input  wire        ps_ack_accepted,
    output reg         cal_exit_req_ps,
    input  wire        spi_initialized_ps,
    input  wire        pattern_active_ps,
    input  wire        normal_ready_ps
);
    localparam [1:0] RESP_OKAY   = 2'b00;
    localparam [1:0] RESP_SLVERR = 2'b10;
    localparam [31:0] MAGIC      = 32'h56344332; // ASCII V4C2, revised register protocol
    localparam [31:0] VERSION    = 32'h0001_0003;

    localparam [11:0] R_MAGIC      = 12'h000;
    localparam [11:0] R_VERSION    = 12'h004;
    localparam [11:0] R_STATE      = 12'h008;
    localparam [11:0] R_COMMAND    = 12'h00C;
    localparam [11:0] R_ACK_SEQ    = 12'h010;
    localparam [11:0] R_ACK_BANK   = 12'h014;
    localparam [11:0] R_READY      = 12'h018;
    localparam [11:0] R_BANK0_SEQ  = 12'h01C;
    localparam [11:0] R_BANK1_SEQ  = 12'h020;
    localparam [11:0] R_COMPLETED  = 12'h024;
    localparam [11:0] R_LAST_ACK   = 12'h028;
    localparam [11:0] R_ERR_COUNT  = 12'h02C;
    localparam [11:0] R_EVENTS     = 12'h030;
    localparam [11:0] R_AVAIL      = 12'h034; // frontend_online, safe during loss
    localparam [11:0] R_EPOCH      = 12'h038; // increments on each frontend loss
    localparam [11:0] R_ACK_EPOCH  = 12'h040; // software-supplied expected epoch
    localparam [11:0] R_CAL_EXIT   = 12'h044; // WO magic CALE, sticky per reset
    localparam [11:0] R_CAL_STATUS = 12'h048; // RO, even when frontend offline
    localparam [31:0] CAL_EXIT_MAGIC = 32'h43414C45;


    localparam [11:0] R_CAPTURE_PERIOD  = 12'h04C;
    localparam [11:0] R_CAPTURE_CONTROL = 12'h050;
    localparam [11:0] R_CAPTURE_STATUS  = 12'h054;
    localparam [11:0] R_ACTIVE_PERIOD   = 12'h058;
    localparam [11:0] R_STARTED         = 12'h05C;
    localparam [11:0] R_REPLAYED        = 12'h060;
    localparam [11:0] R_SKIPPED         = 12'h064;

    reg [31:0] capture_period_config;
    reg capture_outstanding;
    reg capture_done_sticky;
    reg capture_accepted_sticky;

    wire capture_busy_view =
        capture_outstanding || ps_capture_busy;

    wire [31:0] capture_status_word = {
        26'd0,
        frontend_online,
        ps_scheduler_idle,
        ps_active_run,
        capture_accepted_sticky,
        capture_done_sticky,
        capture_busy_view
    };

    reg [11:0] awaddr_hold;
    reg [31:0] wdata_hold;
    reg [3:0] wstrb_hold;
    reg aw_hold_valid, w_hold_valid;

    reg [31:0] ack_sequence_config;
    reg ack_bank_config;
    reg [31:0] ack_epoch_config;
    reg ack_seq_written, ack_bank_written, ack_epoch_written;
    reg [31:0] frontend_epoch;
    reg frontend_online_d;

    reg status_outstanding, ack_outstanding;
    reg status_done_sticky, ack_done_sticky;
    reg last_ack_accepted, command_error_sticky;
    reg [31:0] command_error_count;

    wire status_busy_view = frontend_online && (status_outstanding || ps_status_busy);
    wire ack_busy_view = frontend_online && (ack_outstanding || ps_ack_busy);
    wire [31:0] state_word = {
        26'd0, command_error_sticky, last_ack_accepted,
        ack_done_sticky, status_done_sticky, ack_busy_view, status_busy_view
    };

    assign s_axi_awready = rst_n && !aw_hold_valid && !s_axi_bvalid;
    assign s_axi_wready  = rst_n && !w_hold_valid && !s_axi_bvalid;
    assign s_axi_arready = rst_n && !s_axi_rvalid;

    // Fully decoded reads; no aliasing from high address bits.
    always @(posedge s_axi_aclk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_rvalid <= 1'b0;
            s_axi_rresp <= RESP_OKAY;
            s_axi_rdata <= 32'd0;
        end else begin
            if (s_axi_rvalid && s_axi_rready)
                s_axi_rvalid <= 1'b0;
            if (s_axi_arvalid && s_axi_arready) begin
                s_axi_rvalid <= 1'b1;
                s_axi_rresp <= RESP_OKAY;
                case (s_axi_araddr)
                    R_MAGIC:       s_axi_rdata <= MAGIC;
                    R_VERSION:     s_axi_rdata <= VERSION;
                    R_STATE:       s_axi_rdata <= state_word;
                    R_COMMAND:     s_axi_rdata <= 32'd0; // WO
                    R_ACK_SEQ:     s_axi_rdata <= ack_sequence_config;
                    R_ACK_BANK:    s_axi_rdata <= {31'd0,ack_bank_config};
                    R_ACK_EPOCH:   s_axi_rdata <= ack_epoch_config;
                    R_READY:       s_axi_rdata <= frontend_online ? {30'd0,ps_frame_ready} : 32'd0;
                    R_BANK0_SEQ:   s_axi_rdata <= frontend_online ? ps_bank0_sequence : 32'd0;
                    R_BANK1_SEQ:   s_axi_rdata <= frontend_online ? ps_bank1_sequence : 32'd0;
                    R_COMPLETED:   s_axi_rdata <= frontend_online ? ps_completed_frames : 32'd0;
                    R_LAST_ACK:    s_axi_rdata <= {31'd0,last_ack_accepted};
                    R_ERR_COUNT:   s_axi_rdata <= command_error_count;
                    R_EVENTS:      s_axi_rdata <= {29'd0,command_error_sticky,ack_done_sticky,status_done_sticky};
                    R_AVAIL:       s_axi_rdata <= {31'd0,frontend_online};
                    R_EPOCH:       s_axi_rdata <= frontend_epoch;
                    R_CAL_EXIT:    s_axi_rdata <= 32'd0;
                    R_CAPTURE_PERIOD:
                        s_axi_rdata <= capture_period_config;
                    R_CAPTURE_CONTROL:
                        s_axi_rdata <= 32'd0;
                    R_CAPTURE_STATUS:
                        s_axi_rdata <= frontend_online ?
                            capture_status_word : 32'd0;
                    R_ACTIVE_PERIOD:
                        s_axi_rdata <= frontend_online ?
                            ps_active_period : 32'd0;
                    R_STARTED:
                        s_axi_rdata <= frontend_online ?
                            ps_captures_started : 32'd0;
                    R_REPLAYED:
                        s_axi_rdata <= frontend_online ?
                            ps_captures_replayed : 32'd0;
                    R_SKIPPED:
                        s_axi_rdata <= frontend_online ?
                            ps_skipped_windows : 32'd0;
                    R_CAL_STATUS:  s_axi_rdata <= {27'd0,frontend_online,cal_exit_req_ps,normal_ready_ps,pattern_active_ps,spi_initialized_ps};
                    default: begin
                        s_axi_rdata <= 32'd0;
                        s_axi_rresp <= RESP_SLVERR;
                    end
                endcase
            end
        end
    end

    // Capture AW and W independently. Execute once BOTH are present.
    always @(posedge s_axi_aclk or negedge rst_n) begin
        if (!rst_n) begin
            aw_hold_valid <= 1'b0;
            w_hold_valid <= 1'b0;
            awaddr_hold <= 12'd0;
            wdata_hold <= 32'd0;
            wstrb_hold <= 4'd0;
            s_axi_bresp <= RESP_OKAY;
            s_axi_bvalid <= 1'b0;
            ack_sequence_config <= 32'd0;
            ack_bank_config <= 1'b0;
            ack_epoch_config <= 32'd0;
            ack_seq_written <= 1'b0;
            ack_bank_written <= 1'b0;
            ack_epoch_written <= 1'b0;
            frontend_epoch <= 32'd0;
            frontend_online_d <= 1'b0;
            ps_status_req <= 1'b0;
            ps_ack_req <= 1'b0;
            cal_exit_req_ps <= 1'b0;

            capture_period_config <= 32'd125000000;
            ps_capture_req <= 1'b0;
            ps_capture_enable <= 1'b0;
            ps_capture_period <= 32'd125000000;

            capture_outstanding <= 1'b0;
            capture_done_sticky <= 1'b0;
            capture_accepted_sticky <= 1'b0;
            ps_ack_bank <= 1'b0;
            ps_ack_expected_sequence <= 32'd0;
            status_outstanding <= 1'b0;
            ack_outstanding <= 1'b0;
            status_done_sticky <= 1'b0;
            ack_done_sticky <= 1'b0;
            last_ack_accepted <= 1'b0;
            command_error_sticky <= 1'b0;
            command_error_count <= 32'd0;
        end else begin
            frontend_online_d <= frontend_online;

            ps_capture_req <= 1'b0;

            if (!frontend_online) begin
                capture_outstanding <= 1'b0;
                capture_done_sticky <= 1'b0;
                capture_accepted_sticky <= 1'b0;
                ps_capture_enable <= 1'b0;
            end else if (
                capture_outstanding && ps_capture_done
            ) begin
                capture_outstanding <= 1'b0;
                capture_done_sticky <= 1'b1;
                capture_accepted_sticky <= ps_capture_accepted;
            end
            ps_status_req <= 1'b0;
            ps_ack_req <= 1'b0;
            // Frontend loss must never reset AXI READY/VALID. Cancel only
            // the control-plane transactions; the AXI bus stays responsive.
            if (!frontend_online) begin
                status_outstanding <= 1'b0;
                ack_outstanding <= 1'b0;
                status_done_sticky <= 1'b0;
                ack_done_sticky <= 1'b0;
                last_ack_accepted <= 1'b0;
                ack_seq_written <= 1'b0;
                ack_bank_written <= 1'b0;
                ack_epoch_written <= 1'b0;
                if (frontend_online_d)
                    frontend_epoch <= frontend_epoch + 1'b1;
            end else begin
                if (ps_status_valid && status_outstanding) begin
                    status_outstanding <= 1'b0;
                    status_done_sticky <= 1'b1;
                end
                if (ps_ack_done && ack_outstanding) begin
                    ack_outstanding <= 1'b0;
                    ack_done_sticky <= 1'b1;
                    last_ack_accepted <= ps_ack_accepted;
                end
            end

            if (s_axi_bvalid && s_axi_bready)
                s_axi_bvalid <= 1'b0;
            if (s_axi_awvalid && s_axi_awready) begin
                awaddr_hold <= s_axi_awaddr;
                aw_hold_valid <= 1'b1;
            end
            if (s_axi_wvalid && s_axi_wready) begin
                wdata_hold <= s_axi_wdata;
                wstrb_hold <= s_axi_wstrb;
                w_hold_valid <= 1'b1;
            end
            if (aw_hold_valid && w_hold_valid && !s_axi_bvalid) begin
                aw_hold_valid <= 1'b0;
                w_hold_valid <= 1'b0;
                s_axi_bvalid <= 1'b1;
                s_axi_bresp <= RESP_OKAY;
                if (wstrb_hold != 4'hF) begin
                    s_axi_bresp <= RESP_SLVERR;
                    command_error_sticky <= 1'b1;
                    command_error_count <= command_error_count + 1'b1;
                end else begin
                    case (awaddr_hold)
                        R_ACK_SEQ: begin
                            if (!frontend_online) begin
                                s_axi_bresp <= RESP_SLVERR;
                                command_error_sticky <= 1'b1;
                                command_error_count <= command_error_count + 1'b1;
                            end else begin
                                ack_sequence_config <= wdata_hold;
                                ack_seq_written <= 1'b1;
                            end
                        end
                        R_ACK_EPOCH: begin
                            if (!frontend_online) begin
                                s_axi_bresp <= RESP_SLVERR;
                                command_error_sticky <= 1'b1;
                                command_error_count <= command_error_count + 1'b1;
                            end else begin
                                ack_epoch_config <= wdata_hold;
                                ack_epoch_written <= 1'b1;
                            end
                        end
                        R_ACK_BANK: begin
                            if (!frontend_online || wdata_hold > 1) begin
                                s_axi_bresp <= RESP_SLVERR;
                                command_error_sticky <= 1'b1;
                                command_error_count <= command_error_count + 1'b1;
                            end else begin
                                ack_bank_config <= wdata_hold[0];
                                ack_bank_written <= 1'b1;
                            end
                        end
                        R_COMMAND: begin
                            // One command at a time, including transactions not
                            // yet acknowledged by the mailbox input pipeline.
                            if (!frontend_online ||
                                (wdata_hold != 32'h1 && wdata_hold != 32'h2) ||
                                status_busy_view || ack_busy_view || capture_busy_view ||
                                ((wdata_hold == 32'h2) &&
                                  (!ack_seq_written || !ack_bank_written || !ack_epoch_written ||
                                   ack_epoch_config != frontend_epoch))) begin
                                s_axi_bresp <= RESP_SLVERR;
                                command_error_sticky <= 1'b1;
                                command_error_count <= command_error_count + 1'b1;
                            end else if (wdata_hold == 32'h1) begin
                                status_outstanding <= 1'b1;
                                status_done_sticky <= 1'b0;
                                ps_status_req <= 1'b1;
                            end else begin
                                // Latch expected identity for duration of request.
                                ps_ack_bank <= ack_bank_config;
                                ps_ack_expected_sequence <= ack_sequence_config;
                                ack_outstanding <= 1'b1;
                                ack_done_sticky <= 1'b0;
                                last_ack_accepted <= 1'b0;
                                ps_ack_req <= 1'b1;
                            end
                        end
                        R_CAPTURE_PERIOD: begin
                            if (
                                !frontend_online ||
                                capture_busy_view ||
                                wdata_hold < 32'd12500 ||
                                wdata_hold > 32'd125000000
                            ) begin
                                s_axi_bresp <= RESP_SLVERR;
                                command_error_sticky <= 1'b1;
                                command_error_count <=
                                    command_error_count + 1'b1;
                            end else begin
                                capture_period_config <= wdata_hold;
                            end
                        end

                        R_CAPTURE_CONTROL: begin
                            // 1 = START, 2 = STOP.
                            // START requires normal ADC operating mode.
                            // The ADC-domain mailbox independently
                            // verifies the pipeline drain condition.

                            if (
                                !frontend_online ||
                                capture_busy_view ||
                                status_busy_view ||
                                ack_busy_view ||
                                (wdata_hold != 32'd1 &&
                                 wdata_hold != 32'd2) ||
                                ((wdata_hold == 32'd1) &&
                                 (!spi_initialized_ps ||
                                  !normal_ready_ps ||
                                  pattern_active_ps))
                            ) begin
                                s_axi_bresp <= RESP_SLVERR;
                                command_error_sticky <= 1'b1;
                                command_error_count <=
                                    command_error_count + 1'b1;
                            end else begin
                                ps_capture_enable <=
                                    (wdata_hold == 32'd1);

                                ps_capture_period <=
                                    capture_period_config;

                                capture_outstanding <= 1'b1;
                                capture_done_sticky <= 1'b0;
                                capture_accepted_sticky <= 1'b0;

                                ps_capture_req <= 1'b1;
                            end
                        end

                        R_CAL_EXIT: begin
                            // Fail closed: no exit until checkerboard has actually
                            // been entered; a wrong word or repeated exit is SLVERR.
                            // This stays asserted until PS peripheral reset.
                            if (wdata_hold != CAL_EXIT_MAGIC ||
                                !spi_initialized_ps || !pattern_active_ps ||
                                normal_ready_ps || cal_exit_req_ps) begin
                                s_axi_bresp <= RESP_SLVERR;
                                command_error_sticky <= 1'b1;
                                command_error_count <= command_error_count + 1'b1;
                            end else begin
                                cal_exit_req_ps <= 1'b1;
                            end
                        end
                        R_EVENTS: begin
                            // W1C. Concurrent completion pulses have SET priority.
                            if (wdata_hold[0] && !ps_status_valid)
                                status_done_sticky <= 1'b0;
                            if (wdata_hold[1] && !ps_ack_done)
                                ack_done_sticky <= 1'b0;
                            if (wdata_hold[2])
                                command_error_sticky <= 1'b0;
                        end
                        default: begin
                            s_axi_bresp <= RESP_SLVERR;
                            command_error_sticky <= 1'b1;
                            command_error_count <= command_error_count + 1'b1;
                        end
                    endcase
                end
            end
        end
    end
endmodule

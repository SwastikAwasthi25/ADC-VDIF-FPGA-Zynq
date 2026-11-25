`timescale 1ns / 1ps
// V4 EXPERIMENTAL PS-clock AXI4-Lite control peripheral.
// Does NOT replace the AXI BRAM Controller (separate 4 KiB address window).
// One outstanding AXI write response, one outstanding AXI read response.
// AW and W channels accepted independently. Full word strobes required for writes.
// No burst/AXI-full behavior. Only status and ACK commands reach the CDC module.
// STATUS snapshot values stay coherent between completed snapshot transactions.
// All status/ACK controls operate in the PS clock domain.
module v4_ps_axil_control (
    input  wire        s_axi_aclk,
    input  wire        rst_n,
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
    output reg         ps_ack_req,
    output reg         ps_ack_bank,
    output reg  [31:0] ps_ack_expected_sequence,
    input  wire        ps_ack_busy,
    input  wire        ps_ack_done,
    input  wire        ps_ack_accepted
);
    localparam [1:0] RESP_OKAY   = 2'b00;
    localparam [1:0] RESP_SLVERR = 2'b10;
    localparam [31:0] MAGIC      = 32'h56344331; // ASCII V4C1
    localparam [31:0] VERSION    = 32'h0001_0000;

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

    reg [11:0] awaddr_hold;
    reg [31:0] wdata_hold;
    reg [3:0] wstrb_hold;
    reg aw_hold_valid, w_hold_valid;

    reg [31:0] ack_sequence_config;
    reg ack_bank_config;
    reg status_outstanding, ack_outstanding;
    reg status_done_sticky, ack_done_sticky;
    reg last_ack_accepted, command_error_sticky;
    reg [31:0] command_error_count;

    wire status_busy_view = status_outstanding || ps_status_busy;
    wire ack_busy_view = ack_outstanding || ps_ack_busy;
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
                    R_READY:       s_axi_rdata <= {30'd0,ps_frame_ready};
                    R_BANK0_SEQ:   s_axi_rdata <= ps_bank0_sequence;
                    R_BANK1_SEQ:   s_axi_rdata <= ps_bank1_sequence;
                    R_COMPLETED:   s_axi_rdata <= ps_completed_frames;
                    R_LAST_ACK:    s_axi_rdata <= {31'd0,last_ack_accepted};
                    R_ERR_COUNT:   s_axi_rdata <= command_error_count;
                    R_EVENTS:      s_axi_rdata <= {29'd0,command_error_sticky,ack_done_sticky,status_done_sticky};
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
            ps_status_req <= 1'b0;
            ps_ack_req <= 1'b0;
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
            ps_status_req <= 1'b0;
            ps_ack_req <= 1'b0;
            if (ps_status_valid) begin
                status_outstanding <= 1'b0;
                status_done_sticky <= 1'b1;
            end
            if (ps_ack_done) begin
                ack_outstanding <= 1'b0;
                ack_done_sticky <= 1'b1;
                last_ack_accepted <= ps_ack_accepted;
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
                        R_ACK_SEQ:  ack_sequence_config <= wdata_hold;
                        R_ACK_BANK: begin
                            if (wdata_hold <= 1)
                                ack_bank_config <= wdata_hold[0];
                            else begin
                                s_axi_bresp <= RESP_SLVERR;
                                command_error_sticky <= 1'b1;
                                command_error_count <= command_error_count + 1'b1;
                            end
                        end
                        R_COMMAND: begin
                            // One command at a time, including transactions not
                            // yet acknowledged by the mailbox input pipeline.
                            if ((wdata_hold != 32'h1 && wdata_hold != 32'h2) ||
                                status_busy_view || ack_busy_view) begin
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

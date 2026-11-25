`timescale 1ns / 1ps

module adc_ch0_frame_buffer (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start_capture,
    input  wire        sample_valid,
    input  wire [13:0] adc_raw_ch0,

    output wire [7:0]  m_axis_tdata,
    output wire        m_axis_tvalid,
    input  wire        m_axis_tready,

    output reg         capture_done,
    output reg         replay_done,
    output reg  [10:0] sample_count
);

    localparam [2:0]
        IDLE      = 3'd0,
        CAPTURE   = 3'd1,
        FETCH     = 3'd2,
        READ_WAIT = 3'd3,
        STREAM    = 3'd4,
        DONE      = 3'd5;

    reg [2:0] state;
    reg [9:0] wr_addr;
    reg [9:0] rd_addr;

    (* ram_style = "block" *)
    reg [13:0] sample_mem [0:1023];

    reg [13:0] read_data;

    // Independent synchronous write port.
    wire write_enable = (state == CAPTURE) && sample_valid;

    always @(posedge clk) begin
        if (write_enable)
            sample_mem[wr_addr] <= adc_raw_ch0;
    end

    // Synchronous BRAM read port.
    // No reset or asynchronous read on the memory output.
    always @(posedge clk) begin
        if (state == FETCH)
            read_data <= sample_mem[rd_addr];
    end

    // ADC A4=0x00: offset binary -> two's complement.
    // Toggle bit 13, then retain the upper eight bits.
    assign m_axis_tdata = read_data[13:6] ^ 8'h80;
    assign m_axis_tvalid = (state == STREAM) && rst_n;

    always @(posedge clk) begin
        if (!rst_n) begin
            state         <= IDLE;
            wr_addr       <= 0;
            rd_addr       <= 0;
            capture_done  <= 0;
            replay_done   <= 0;
            sample_count  <= 0;
        end else begin
            case (state)

                IDLE, DONE: begin
                    if (start_capture) begin
                        wr_addr      <= 0;
                        rd_addr      <= 0;
                        sample_count <= 0;
                        capture_done <= 0;
                        replay_done  <= 0;
                        state        <= CAPTURE;
                    end
                end

                CAPTURE: begin
                    if (sample_valid) begin
                        sample_count <= sample_count + 1'b1;

                        if (wr_addr == 10'd1023) begin
                            capture_done <= 1'b1;
                            rd_addr <= 0;
                            state <= FETCH;
                        end else begin
                            wr_addr <= wr_addr + 1'b1;
                        end
                    end
                end

                FETCH: begin
                    state <= READ_WAIT;
                end

                READ_WAIT: begin
                    state <= STREAM;
                end

                STREAM: begin
                    if (m_axis_tready) begin
                        if (rd_addr == 10'd1023) begin
                            replay_done <= 1'b1;
                            state <= DONE;
                        end else begin
                            rd_addr <= rd_addr + 1'b1;
                            state <= FETCH;
                        end
                    end
                end

                default: state <= IDLE;

            endcase
        end
    end

endmodule

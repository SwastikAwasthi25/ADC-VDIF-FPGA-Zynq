`timescale 1ns / 1ps
// Experimental, single-clock two-bank AXI-Stream -> BRAM frame sink.
// Not a live ADC recorder or drop-in replacement for the existing verified M3 BD.
// All inputs, including sw_ack_valid/bank, must be synchronous to clk.
// The PS/AXI clock crossing and BRAM Port B ownership are integration work.
module vdif_pingpong_frame_sink #(
    parameter integer FRAME_WORDS = 264,
    parameter integer BANK_WORDS  = 512
) (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] s_axis_tdata,
    input  wire        s_axis_tvalid,
    input  wire        s_axis_tlast,
    output wire        s_axis_tready,

    // Registered BRAM Port-A write interface: byte address, 4-byte words.
    output reg  [31:0] bram_addr,
    output reg  [31:0] bram_data,
    output reg         bram_we,

    // Published frames remain immutable until explicitly acknowledged.
    output reg  [1:0]  frame_ready,
    output reg  [31:0] bank0_sequence,
    output reg  [31:0] bank1_sequence,
    input  wire        sw_ack_valid,
    input  wire        sw_ack_bank,

    output reg  [31:0] completed_frames,
    output reg  [31:0] malformed_frames,
    // AXIS stalled due to both banks occupied. NOT a count of lost ADC samples.
    output reg  [31:0] blocked_cycles,
    output reg  [31:0] blocked_episodes,
    output reg  [31:0] rejected_acks
);
    localparam integer INDEX_W = (FRAME_WORDS <= 2) ? 1 : $clog2(FRAME_WORDS);

    reg [INDEX_W-1:0] word_index;
    reg                 writing_active;
    reg                 active_bank;
    reg                 preferred_bank;
    reg                 draining_bad_frame;
    reg                 commit_pending;
    reg                 commit_bank;
    reg                 in_blocked_episode;

    wire preferred_free = !frame_ready[preferred_bank];
    wire opposite_free  = !frame_ready[~preferred_bank];
    wire candidate_bank = preferred_free ? preferred_bank : ~preferred_bank;
    wire available_bank = preferred_free || opposite_free;
    wire selected_bank  = writing_active ? active_bank : candidate_bank;

    // A malformed oversized packet is drained through TLAST without writing.
    // One cycle after the last registered BRAM write is reserved for commit.
    assign s_axis_tready = rst_n && !commit_pending &&
        (draining_bad_frame || writing_active || available_bank);
    wire transfer = s_axis_tvalid && s_axis_tready;
    wire banks_full_stall = rst_n && s_axis_tvalid && !s_axis_tready &&
        !commit_pending && !draining_bad_frame && !writing_active && !available_bank;

    always @(posedge clk) begin
        if (!rst_n) begin
            word_index        <= {INDEX_W{1'b0}};
            writing_active    <= 1'b0;
            active_bank       <= 1'b0;
            preferred_bank    <= 1'b0;
            draining_bad_frame <= 1'b0;
            commit_pending    <= 1'b0;
            commit_bank       <= 1'b0;
            in_blocked_episode <= 1'b0;
            bram_addr         <= 32'd0;
            bram_data         <= 32'd0;
            bram_we           <= 1'b0;
            frame_ready       <= 2'b00;
            bank0_sequence    <= 32'd0;
            bank1_sequence    <= 32'd0;
            completed_frames  <= 32'd0;
            malformed_frames  <= 32'd0;
            blocked_cycles    <= 32'd0;
            blocked_episodes  <= 32'd0;
            rejected_acks     <= 32'd0;
        end else begin
            bram_we <= 1'b0;

            if (sw_ack_valid) begin
                if (frame_ready[sw_ack_bank])
                    frame_ready[sw_ack_bank] <= 1'b0;
                else
                    rejected_acks <= rejected_acks + 1'b1;
            end

            if (banks_full_stall) begin
                blocked_cycles <= blocked_cycles + 1'b1;
                if (!in_blocked_episode)
                    blocked_episodes <= blocked_episodes + 1'b1;
                in_blocked_episode <= 1'b1;
            end else begin
                in_blocked_episode <= 1'b0;
            end

            // Publish only AFTER the last registered write was sampled
            // by the synchronous BRAM on this same rising edge.
            if (commit_pending) begin
                frame_ready[commit_bank] <= 1'b1;
                if (commit_bank == 1'b0)
                    bank0_sequence <= completed_frames;
                else
                    bank1_sequence <= completed_frames;
                completed_frames <= completed_frames + 1'b1;
                commit_pending <= 1'b0;
            end

            if (transfer) begin
                if (draining_bad_frame) begin
                    if (s_axis_tlast)
                        draining_bad_frame <= 1'b0;
                end else begin
                    bram_we   <= 1'b1;
                    // BANK_WORDS is a constant stride in words, converted to bytes.
                    bram_addr <= ((selected_bank ? BANK_WORDS : 0) + word_index) * 4;
                    bram_data <= s_axis_tdata;

                    if (!writing_active)
                        active_bank <= selected_bank;

                    if (word_index == FRAME_WORDS - 1) begin
                        writing_active <= 1'b0;
                        word_index <= {INDEX_W{1'b0}};
                        preferred_bank <= ~selected_bank;
                        if (s_axis_tlast) begin
                            commit_pending <= 1'b1;
                            commit_bank <= selected_bank;
                        end else begin
                            malformed_frames <= malformed_frames + 1'b1;
                            draining_bad_frame <= 1'b1;
                        end
                    end else if (s_axis_tlast) begin
                        // Early TLAST: partial words may exist in free bank,
                        // but no publication occurs; next frame can overwrite.
                        writing_active <= 1'b0;
                        word_index <= {INDEX_W{1'b0}};
                        malformed_frames <= malformed_frames + 1'b1;
                    end else begin
                        writing_active <= 1'b1;
                        word_index <= word_index + 1'b1;
                    end
                end
            end
        end
    end
endmodule

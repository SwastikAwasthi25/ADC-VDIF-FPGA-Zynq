`timescale 1ns / 1ps

module tb_m25_payload_scoreboard;

    // Reuse the existing verified simulation stimulus.
    tb_m25_adc_vdif_bram u_tb();

    reg [7:0] accepted [0:1023];

    integer accepted_n = 0;
    integer mismatch_le = 0;
    integer mismatch_be = 0;
    integer i;

    reg [31:0] expected_le;
    reg [31:0] expected_be;
    reg [31:0] actual;

    always @(posedge u_tb.adc_clk) begin
        if (u_tb.rst_n &&
            u_tb.stream_valid &&
            u_tb.stream_ready) begin

            if (accepted_n >= 1024)
                $fatal(1, "Too many accepted ADC bytes");

            accepted[accepted_n] = u_tb.stream_data;
            accepted_n = accepted_n + 1;
        end
    end

    initial begin
        wait (u_tb.packet_done === 1'b1);

        repeat (4) @(negedge u_tb.adc_clk);

        if (accepted_n != 1024)
            $fatal(1, "Expected 1024 accepted bytes");

        for (i = 0; i < 256; i = i + 1) begin

            expected_le = {
                accepted[4*i+3],
                accepted[4*i+2],
                accepted[4*i+1],
                accepted[4*i]
            };

            expected_be = {
                accepted[4*i],
                accepted[4*i+1],
                accepted[4*i+2],
                accepted[4*i+3]
            };

            actual = u_tb.memory[i+8];

            if (actual !== expected_le)
                mismatch_le = mismatch_le + 1;

            if (actual !== expected_be)
                mismatch_be = mismatch_be + 1;

            if (i < 4) begin
                $display(
                    "WORD_%0d ACTUAL=%08h LE=%08h BE=%08h",
                    i+8, actual, expected_le, expected_be
                );
            end
        end

        $display("ACCEPTED_BYTES=%0d", accepted_n);
        $display("PAYLOAD_WORDS_CHECKED=256");
        $display("MISMATCH_LE=%0d", mismatch_le);
        $display("MISMATCH_BE=%0d", mismatch_be);

        if (mismatch_le == 0)
            $display("PASS: Exact little-endian payload match");
        else if (mismatch_be == 0)
            $display("PASS: Exact big-endian payload match");
        else
            $display("CHECK: Payload requires format analysis");
    end

endmodule

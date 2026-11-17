`timescale 1ns / 1ps

module tb_m25_real_bram;

    // Existing simulation pipeline, copied without RTL changes.
    tb_m25_adc_vdif_bram_bramtest u_tb();

    reg [31:0] read_addr = 0;
    wire [31:0] read_data;

    integer i;
    integer mismatches = 0;

    // Actual Xilinx-generated Block Memory Generator IP.
    design_1_blk_mem_gen_0_0 u_real_bram (
        .clka  (u_tb.adc_clk),
        .ena   (1'b1),
        .wea   ({4{u_tb.bram_we}}),
        .addra (u_tb.bram_addr),
        .dina  (u_tb.bram_data),
        .douta (),

        .clkb  (u_tb.adc_clk),
        .enb   (u_tb.packet_done),
        .web   (4'b0000),
        .addrb (read_addr),
        .dinb  (32'd0),
        .doutb (read_data)
    );

    initial begin
        wait (u_tb.packet_done === 1'b1);

        repeat (3) @(negedge u_tb.adc_clk);

        if (u_tb.writes != 264 ||
            u_tb.adc_beats != 1024 ||
            u_tb.pps_beats != 1)
            $fatal(1, "Pipeline counts incorrect");

        $display("=== ACTUAL XILINX BRAM READBACK ===");

        for (i = 0; i < 264; i = i + 1) begin

            @(negedge u_tb.adc_clk);
            read_addr = i * 4;

            @(posedge u_tb.adc_clk);
            #2;

            if (read_data !== u_tb.memory[i]) begin
                mismatches = mismatches + 1;

                if (mismatches <= 10)
                    $display(
                        "MISMATCH word=%0d addr=%0d actual=%08h expected=%08h",
                        i, i*4, read_data, u_tb.memory[i]
                    );
            end

            if (i < 4 || i == 263)
                $display(
                    "READBACK word=%0d addr=%0d data=%08h",
                    i, i*4, read_data
                );
        end

        $display("READBACK_WORDS=264");
        $display("REAL_BRAM_MISMATCHES=%0d", mismatches);

        if (mismatches != 0)
            $fatal(1, "FAIL: Actual BRAM content mismatch");

        $display("PASS: Actual Xilinx BRAM 264-word readback");
    end

endmodule


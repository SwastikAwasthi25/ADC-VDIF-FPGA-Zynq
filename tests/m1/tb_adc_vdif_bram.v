`timescale 1ns/1ps
// Integration TB: real captured ADC replay -> packaged HLS VDIF IP -> exact
// Sudhanshu axis_bram_writer RTL -> synchronous BRAM model -> payload scoreboard.
// Expected HLS module: design_1_vdif_packetizer_0_0 (from collaborator's BD IP).
// No HDL changes or assumptions about DMA/PS/physical ADC performance are made.
module tb_adc_vdif_bram;
    localparam NSAMPLES = 1024;
    localparam FRAME_WORDS = 264;
    reg clk = 0;
    always #4 clk = ~clk;
    reg rst_n = 0;
    reg [7:0] adc_data = 0;
    reg adc_valid = 0;
    wire adc_ready;
    reg [7:0] pps_data = 0;
    reg pps_valid = 0;
    wire pps_ready;
    wire [31:0] pkt_data;
    wire [3:0] pkt_keep, pkt_strb;
    wire pkt_valid, pkt_ready, pkt_last;
    wire [31:0] bram_addr, bram_data;
    wire bram_we, packet_done;
    reg rearm = 0;

    reg [7:0] samples [0:NSAMPLES-1];
    reg [31:0] bram [0:2047];
    integer i, nwords=0, nlast=0, errors=0, ninputs=0;
    integer expected_word_index;
    reg [31:0] expword;

    initial $readmemh("adc_ch0_1024.mem", samples);

    design_1_vdif_packetizer_0_0 pkt (
        .ap_clk(clk), .ap_rst_n(rst_n),
        .adc_in_TDATA(adc_data), .adc_in_TVALID(adc_valid), .adc_in_TREADY(adc_ready),
        .pps_in_TDATA(pps_data), .pps_in_TVALID(pps_valid), .pps_in_TREADY(pps_ready),
        .packet_out_TDATA(pkt_data), .packet_out_TKEEP(pkt_keep),
        .packet_out_TSTRB(pkt_strb), .packet_out_TVALID(pkt_valid),
        .packet_out_TREADY(pkt_ready), .packet_out_TLAST(pkt_last)
    );

    axis_bram_writer #(.FRAME_WORDS(FRAME_WORDS), .BRAM_WORDS(2048)) writer (
        .clk(clk), .rst_n(rst_n), .rearm_req(rearm),
        .s_axis_tdata(pkt_data), .s_axis_tvalid(pkt_valid),
        .s_axis_tlast(pkt_last), .s_axis_tready(pkt_ready),
        .bram_addr(bram_addr), .bram_data(bram_data),
        .bram_we(bram_we), .packet_done(packet_done)
    );

    // Actual writer outputs are registered. BRAM samples these a cycle later.
    always @(posedge clk) begin
        if (bram_we) begin
            if (bram_addr[31:2] >= 2048) begin
                $display("FAIL: BRAM address out of range: %h", bram_addr);
                errors = errors + 1;
            end else bram[bram_addr[31:2]] <= bram_data;
        end
    end

    // Scoreboard at AXIS output, independent of the subsequent BRAM readback.
    always @(posedge clk) begin
        if (rst_n && pkt_valid && pkt_ready) begin
            if (nwords >= FRAME_WORDS) begin
                $display("FAIL: unexpected output word %0d", nwords);
                errors = errors + 1;
            end else begin
                if (pkt_keep !== 4'hf || pkt_strb !== 4'hf) begin
                    $display("FAIL: keep/strb mismatch at %0d keep=%h strb=%h", nwords, pkt_keep, pkt_strb);
                    errors = errors + 1;
                end
                if (nwords >= 8) begin
                    expected_word_index = (nwords-8)*4;
                    expword = {samples[expected_word_index+3], samples[expected_word_index+2],
                               samples[expected_word_index+1], samples[expected_word_index]};
                    if (pkt_data !== expword) begin
                        if (errors < 8) $display("FAIL: payload word=%0d got=%h expected=%h", nwords, pkt_data, expword);
                        errors = errors + 1;
                    end
                end
                if (pkt_last !== (nwords == FRAME_WORDS-1)) begin
                    $display("FAIL: TLAST word=%0d TLAST=%b", nwords, pkt_last);
                    errors = errors + 1;
                end
                if (pkt_last) nlast = nlast + 1;
            end
            nwords = nwords + 1;
        end
    end

    initial begin
        repeat (16) @(negedge clk);
        rst_n = 1;
        // As in collaborator standalone packetizer TB, send one PPS handshake.
        @(negedge clk); pps_valid = 1;
        while (!pps_ready) @(posedge clk);
        @(negedge clk); pps_valid = 0;
        for (i=0; i<NSAMPLES; i=i+1) begin
            @(negedge clk);
            adc_data = samples[i];
            adc_valid = 1;
            // Hold byte stable until the packetizer accepts it.
            @(posedge clk);
            while (adc_ready !== 1'b1) @(posedge clk);
            ninputs = ninputs + 1;
            @(negedge clk); adc_valid = 0;
        end
        wait (packet_done === 1'b1);
        repeat (5) @(posedge clk);
        if (ninputs != NSAMPLES || nwords != FRAME_WORDS || nlast != 1) begin
            $display("FAIL: input=%0d output=%0d TLAST=%0d", ninputs, nwords, nlast);
            errors = errors + 1;
        end
        for(i=0;i<256;i=i+1) begin
            expword = {samples[i*4+3],samples[i*4+2],samples[i*4+1],samples[i*4]};
            if(bram[i+8] !== expword) begin
                if(errors < 8) $display("FAIL: BRAM word %0d got=%h expected=%h",i+8,bram[i+8],expword);
                errors = errors + 1;
            end
        end
        if (errors == 0) $display("PASS: 1024 real ADC-derived bytes -> VDIF -> 264 words -> BRAM verified");
        else $display("FAIL: %0d errors", errors);
        $finish;
    end
    initial begin
        #5000000;
        $display("FAIL: simulation timeout, accepted_in=%0d output=%0d", ninputs,nwords);
        $finish;
    end
endmodule

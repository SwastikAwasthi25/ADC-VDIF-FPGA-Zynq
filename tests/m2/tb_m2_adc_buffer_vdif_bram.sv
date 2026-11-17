`timescale 1ns/1ps
// M2 standalone RTL simulation: reconstructed 14-bit ADC stimulus
// -> NEW adc_ch0_frame_buffer -> ACTUAL existing HLS VDIF RTL -> actual writer
// -> synchronous simulation BRAM. No live ADC/PHY/PS/DDR/DMA represented.
module tb_m2_adc_buffer_vdif_bram;
    localparam integer NSAMPLES = 1024;
    localparam integer FRAME_WORDS = 264;
    reg clk = 1'b0;
    always #4 clk = ~clk;
    reg rst_n = 1'b0, start_capture = 1'b0, sample_valid = 1'b0;
    reg [13:0] adc_raw_ch0 = 14'd0;
    wire [7:0] buf_data;
    wire buf_valid, buf_ready, capture_done, replay_done;
    wire [10:0] sample_count;
    reg [7:0] pps_data = 8'd0;
    reg pps_valid = 1'b0;
    wire pps_ready;
    wire [31:0] pkt_data;
    wire [3:0] pkt_keep, pkt_strb;
    wire pkt_valid, pkt_ready;
    wire [0:0] pkt_last;
    wire [31:0] bram_addr, bram_data;
    wire bram_we, packet_done;
    reg rearm_req = 1'b0;
    reg [13:0] raw_samples [0:1023];
    reg [7:0] expected [0:1023];
    reg [31:0] bram [0:2047];
    integer i, ninput = 0, nwords = 0, nlast = 0, nstall = 0, errors = 0;
    integer offset;
    reg [31:0] expected_word;
    reg stalled = 0;
    reg [7:0] held_data;

    initial begin
        $readmemh("D:/ADC_VDIF_M1/m2_live_adc_ch0/integration_tools/vectors/m2_ch0_offset_binary.mem", raw_samples);
        $readmemh("D:/ADC_VDIF_M1/adc_vdif_milestone1/adc_ch0_1024.mem", expected);
    end

    adc_ch0_frame_buffer adapter (
        .clk(clk), .rst_n(rst_n), .start_capture(start_capture),
        .sample_valid(sample_valid), .adc_raw_ch0(adc_raw_ch0),
        .m_axis_tdata(buf_data), .m_axis_tvalid(buf_valid),
        .m_axis_tready(buf_ready), .capture_done(capture_done),
        .replay_done(replay_done), .sample_count(sample_count)
    );

    design_1_vdif_packetizer_0_0 pkt (
        .ap_clk(clk), .ap_rst_n(rst_n),
        .adc_in_TDATA(buf_data), .adc_in_TVALID(buf_valid),
        .adc_in_TREADY(buf_ready),
        .pps_in_TDATA(pps_data), .pps_in_TVALID(pps_valid),
        .pps_in_TREADY(pps_ready),
        .packet_out_TDATA(pkt_data), .packet_out_TKEEP(pkt_keep),
        .packet_out_TSTRB(pkt_strb), .packet_out_TVALID(pkt_valid),
        .packet_out_TREADY(pkt_ready), .packet_out_TLAST(pkt_last)
    );

    axis_bram_writer #(.FRAME_WORDS(FRAME_WORDS), .BRAM_WORDS(2048)) writer (
        .clk(clk), .rst_n(rst_n), .rearm_req(rearm_req),
        .s_axis_tdata(pkt_data), .s_axis_tvalid(pkt_valid),
        .s_axis_tlast(pkt_last), .s_axis_tready(pkt_ready),
        .bram_addr(bram_addr), .bram_data(bram_data),
        .bram_we(bram_we), .packet_done(packet_done)
    );

    // Writer outputs are registered; BRAM captures those outputs on next edge.
    always @(posedge clk) begin
        if (bram_we) begin
            if (bram_addr[31:2] >= 2048) $fatal(1, "BRAM address out of bounds");
            bram[bram_addr[31:2]] <= bram_data;
        end
    end

    // Monitor input protocol, quantization, and stall stability.
    always @(posedge clk) begin
        if (rst_n) begin
            if (stalled && (!buf_valid || buf_data !== held_data))
                $fatal(1, "Adapter AXIS data changed under stall");
            if (buf_valid && !buf_ready) begin
                nstall = nstall + 1;
                if (!stalled) held_data = buf_data;
                stalled = 1;
            end
            if (buf_valid && buf_ready) begin
                stalled = 0;
                if (ninput >= NSAMPLES)
                    $fatal(1, "Unexpected extra input handshake");
                if (buf_data !== expected[ninput])
                    $fatal(1, "Adapter mismatch at sample %0d got %02h expected %02h", ninput, buf_data, expected[ninput]);
                ninput = ninput + 1;
            end
        end
    end

    // Independent packet and TLAST scoreboard.
    always @(posedge clk) begin
        if (rst_n && pkt_valid && pkt_ready) begin
            if (nwords >= FRAME_WORDS) $fatal(1, "Extra VDIF word %0d", nwords);
            if (pkt_keep !== 4'hf || pkt_strb !== 4'hf)
                $fatal(1, "Bad TKEEP/TSTRB on word %0d", nwords);
            if (pkt_last !== (nwords == FRAME_WORDS-1))
                $fatal(1, "TLAST wrong on word %0d", nwords);
            if (nwords >= 8) begin
                offset = 4*(nwords-8);
                expected_word = {expected[offset+3], expected[offset+2],
                                 expected[offset+1], expected[offset]};
                if (pkt_data !== expected_word)
                    $fatal(1, "Packet payload word %0d mismatch: %08h vs %08h",nwords,pkt_data,expected_word);
            end
            if (pkt_last) nlast = nlast + 1;
            nwords = nwords + 1;
        end
    end

    initial begin
        repeat (16) @(negedge clk);
        rst_n = 1'b1;
        // Same one-PPS test mode as successful M1 simulation.
        @(negedge clk);
        pps_valid = 1'b1;
        while (!pps_ready) @(posedge clk);
        @(negedge clk);
        pps_valid = 1'b0;

        @(negedge clk);
        start_capture = 1'b1;
        @(negedge clk);
        start_capture = 1'b0;

        for (i = 0; i < NSAMPLES; i = i + 1) begin
            @(negedge clk);
            adc_raw_ch0 = raw_samples[i];
            sample_valid = 1'b1;
        end
        @(negedge clk);
        sample_valid = 1'b0;

        wait (packet_done === 1'b1);
        repeat (6) @(posedge clk);
        #1;

        if (!capture_done || !replay_done || sample_count !== 11'd1024)
            $fatal(1, "Adapter completion/count invalid: captured=%0d done=%0b replay=%0b", sample_count, capture_done, replay_done);
        if (ninput != NSAMPLES || nwords != FRAME_WORDS || nlast != 1)
            $fatal(1, "Counts invalid: input=%0d words=%0d TLAST=%0d", ninput,nwords,nlast);
        if (nstall <= 0) $fatal(1, "No packetizer backpressure observed");
        for (i=0; i<256; i=i+1) begin
            offset = i*4;
            expected_word = {expected[offset+3],expected[offset+2],expected[offset+1],expected[offset]};
            if (bram[i+8] !== expected_word)
                $fatal(1, "BRAM payload mismatch on word %0d: %08h expected %08h",i+8,bram[i+8],expected_word);
        end
        if (bram[2][23:0] !== 24'd132)
            $fatal(1,"VDIF header frame length field mismatch: %08h",bram[2]);

        $display("VDIF_HEADER[0] = %08h", bram[0]);
        $display("VDIF_HEADER[1] = %08h", bram[1]);
        $display("VDIF_HEADER[2] = %08h", bram[2]);
        $display("VDIF_HEADER[3] = %08h", bram[3]);
        $writememh("D:/ADC_VDIF_M1/m2_buffer_vdif_bram_sim/m2_frame_words.mem", bram, 0, FRAME_WORDS-1);
        $display("PASS: M2 adapter -> HLS VDIF -> BRAM, 1024 accepted samples, 264 words");
        $display("Adapter input stall cycles: %0d", nstall);
        $finish;
    end

    initial begin
        #5000000;
        $fatal(1,"M2 simulation TIMEOUT input=%0d words=%0d",ninput,nwords);
    end
endmodule

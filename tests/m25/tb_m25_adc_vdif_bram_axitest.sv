`timescale 1ns / 1ps

module tb_m25_adc_vdif_bram_axitest;

    reg clk_p = 0;
    always #4 clk_p = ~clk_p;
    wire clk_n = ~clk_p;

    reg [6:0] adc_p = 7'h15;
    wire [6:0] adc_n = ~adc_p;

    reg arst_n = 0;
    wire rst_n;
    wire adc_clk;

    // Synthetic changing differential ADC pattern.
    always @(negedge clk_p)
        adc_p <= adc_p + 7'd1;

    adc_reset_sync u_reset (
        .clk(adc_clk),
        .arst_n(arst_n),
        .srst_n(rst_n)
    );

    wire [13:0] adc_data;
    wire adc_valid;
    wire adc_ready;

    rp_adc_capture u_adc (
        .adc_dat_p_i(adc_p),
        .adc_dat_n_i(adc_n),
        .adc_clk_p_i(clk_p),
        .adc_clk_n_i(clk_n),
        .rst_n(rst_n),
        .adc_clk_o(adc_clk),
        .m_axis_tdata(adc_data),
        .m_axis_tvalid(adc_valid),
        .m_axis_tready(adc_ready)
    );

    wire [13:0] sample_data;
    wire sample_valid;

    adc14_axis_tap u_tap (
        .clk(adc_clk),
        .s_axis_tdata(adc_data),
        .s_axis_tvalid(adc_valid),
        .s_axis_tready(adc_ready),
        .sample_data(sample_data),
        .sample_valid(sample_valid)
    );

    wire [7:0] stream_data;
    wire stream_valid;
    wire stream_ready;
    wire capture_done;
    wire replay_done;
    wire [10:0] sample_count;

    adc_ch0_live_bridge u_bridge (
        .clk(adc_clk),
        .rst_n(rst_n),
        .frontend_ready(sample_valid),
        .adc_raw_ch0(sample_data),
        .m_axis_tdata(stream_data),
        .m_axis_tvalid(stream_valid),
        .m_axis_tready(stream_ready),
        .capture_done(capture_done),
        .replay_done(replay_done),
        .sample_count(sample_count)
    );

    wire [7:0] pps_data;
    wire pps_valid;
    wire pps_ready;

    m25_pps_once u_pps (
        .clk(adc_clk),
        .rst_n(rst_n),
        .m_axis_tdata(pps_data),
        .m_axis_tvalid(pps_valid),
        .m_axis_tready(pps_ready)
    );

    wire [31:0] packet_data;
    wire [3:0] packet_keep;
    wire [3:0] packet_strb;
    wire [0:0] packet_last;
    wire packet_valid;
    wire packet_ready;

    design_1_vdif_packetizer_0_0 u_vdif (
        .ap_clk(adc_clk),
        .ap_rst_n(rst_n),

        .adc_in_TDATA(stream_data),
        .adc_in_TVALID(stream_valid),
        .adc_in_TREADY(stream_ready),

        .pps_in_TDATA(pps_data),
        .pps_in_TVALID(pps_valid),
        .pps_in_TREADY(pps_ready),

        .packet_out_TDATA(packet_data),
        .packet_out_TKEEP(packet_keep),
        .packet_out_TSTRB(packet_strb),
        .packet_out_TLAST(packet_last),
        .packet_out_TVALID(packet_valid),
        .packet_out_TREADY(packet_ready)
    );

    wire [31:0] bram_addr;
    wire [31:0] bram_data;
    wire bram_we;
    wire packet_done;

    axis_bram_writer #(
        .FRAME_WORDS(264),
        .BRAM_WORDS(2048)
    ) u_writer (
        .clk(adc_clk),
        .rst_n(rst_n),
        .rearm_req(1'b0),
        .s_axis_tdata(packet_data),
        .s_axis_tvalid(packet_valid),
        .s_axis_tlast(packet_last[0]),
        .s_axis_tready(packet_ready),
        .bram_addr(bram_addr),
        .bram_data(bram_data),
        .bram_we(bram_we),
        .packet_done(packet_done)
    );

    // Behavioral equivalent of 8 KiB BRAM write storage.
    reg [31:0] memory [0:2047];

    integer writes = 0;
    integer adc_beats = 0;
    integer pps_beats = 0;

    always @(posedge adc_clk) begin
        if (rst_n) begin
            if (stream_valid && stream_ready)
                adc_beats = adc_beats + 1;

            if (pps_valid && pps_ready)
                pps_beats = pps_beats + 1;
        end

        if (bram_we) begin
            if (writes >= 264)
                $fatal(1, "Excess BRAM writes");

            if (bram_addr !== (writes * 4))
                $fatal(1, "BRAM address mismatch at word %0d", writes);

            memory[bram_addr[12:2]] <= bram_data;
            writes = writes + 1;
        end
    end

    initial begin
        repeat (20) @(posedge clk_p);
        @(negedge clk_p);
        arst_n = 1;

        wait (packet_done === 1'b1);
        repeat (20000) @(posedge adc_clk);

        $display("CAPTURE_DONE=%b", capture_done);
        $display("REPLAY_DONE=%b", replay_done);
        $display("SAMPLE_COUNT=%0d", sample_count);
        $display("ADC_BEATS=%0d", adc_beats);
        $display("PPS_BEATS=%0d", pps_beats);
        $display("BRAM_WRITES=%0d", writes);

        $display("VDIF_HEADER_0=%08h", memory[0]);
        $display("VDIF_HEADER_1=%08h", memory[1]);
        $display("VDIF_HEADER_2=%08h", memory[2]);
        $display("VDIF_HEADER_3=%08h", memory[3]);

        if (capture_done !== 1'b1 ||
            replay_done !== 1'b1 ||
            sample_count !== 11'd1024 ||
            adc_beats != 1024 ||
            pps_beats != 1 ||
            writes != 264)
            $fatal(1, "FAIL: M2.5 datapath verification");

        $display("PASS: 1024 samples, 1 PPS, 264 BRAM words");
        $finish;
    end

    initial begin
        #2000000;
        $fatal(1, "TIMEOUT: M2.5 pipeline did not finish");
    end

endmodule



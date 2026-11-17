`timescale 1ns / 1ps

module tb_m25_sc_readback;

    // Existing verified ADC -> VDIF -> writer pipeline.
    tb_m25_adc_vdif_bram_axitest u_tb();

    // 50 MHz simulated PS-side AXI clock.
    reg axi_clk = 0;
    always #10 axi_clk = ~axi_clk;

    reg axi_rstn = 0;

    initial begin
        repeat (20) @(negedge axi_clk);
        axi_rstn = 1;
    end

    // AXI4 read address channel.
    reg  [31:0] araddr = 0;
    reg         arvalid = 0;
    wire        arready;

    // AXI4 read data channel.
    wire [31:0] rdata;
    wire [1:0]  rresp;
    wire        rvalid;
    wire        rlast;
    reg         rready = 1;

    // Controller -> BRAM native port.
    wire        b_clk;
    wire        b_en;
    wire        b_rst;
    wire [3:0]  b_we;
    wire [12:0] b_addr;
    wire [31:0] b_wdata;
    wire [31:0] b_rdata;

    // SmartConnect M00_AXI -> BRAM Controller
    wire [12:0] sc_araddr;
    wire [7:0]  sc_arlen;
    wire [2:0]  sc_arsize;
    wire [1:0]  sc_arburst;
    wire        sc_arlock;
    wire [3:0]  sc_arcache;
    wire [2:0]  sc_arprot;
    wire        sc_arvalid;
    wire        sc_arready;

    wire [31:0] sc_rdata;
    wire [1:0]  sc_rresp;
    wire        sc_rlast;
    wire        sc_rvalid;
    wire        sc_rready;

    design_1_axi_smc_0 u_smc (
        .aclk               (axi_clk),
        .aresetn            (axi_rstn),

        // AXI3 PS-side write channels disabled.
        .S00_AXI_awid       (12'd0),
        .S00_AXI_awaddr     (32'd0),
        .S00_AXI_awlen      (4'd0),
        .S00_AXI_awsize     (3'd2),
        .S00_AXI_awburst    (2'b01),
        .S00_AXI_awlock     (2'b00),
        .S00_AXI_awcache    (4'd0),
        .S00_AXI_awprot     (3'd0),
        .S00_AXI_awqos      (4'd0),
        .S00_AXI_awvalid    (1'b0),

        .S00_AXI_wid        (12'd0),
        .S00_AXI_wdata      (32'd0),
        .S00_AXI_wstrb      (4'd0),
        .S00_AXI_wlast      (1'b0),
        .S00_AXI_wvalid     (1'b0),
        .S00_AXI_bready     (1'b1),

        // AXI3 PS-side read request.
        .S00_AXI_arid       (12'd0),
        .S00_AXI_araddr     (araddr),
        .S00_AXI_arlen      (4'd0),
        .S00_AXI_arsize     (3'd2),
        .S00_AXI_arburst    (2'b01),
        .S00_AXI_arlock     (2'b00),
        .S00_AXI_arcache    (4'd0),
        .S00_AXI_arprot     (3'd0),
        .S00_AXI_arqos      (4'd0),
        .S00_AXI_arvalid    (arvalid),
        .S00_AXI_arready    (arready),

        .S00_AXI_rdata      (rdata),
        .S00_AXI_rresp      (rresp),
        .S00_AXI_rlast      (rlast),
        .S00_AXI_rvalid     (rvalid),
        .S00_AXI_rready     (rready),

        // AXI4 M00 write channel:
        // No writes are issued in this read-only test.
        .M00_AXI_awready    (1'b1),
        .M00_AXI_wready     (1'b1),
        .M00_AXI_bresp      (2'b00),
        .M00_AXI_bvalid     (1'b0),

        // AXI4 read request to BRAM Controller.
        .M00_AXI_araddr     (sc_araddr),
        .M00_AXI_arlen      (sc_arlen),
        .M00_AXI_arsize     (sc_arsize),
        .M00_AXI_arburst    (sc_arburst),
        .M00_AXI_arlock     (sc_arlock),
        .M00_AXI_arcache    (sc_arcache),
        .M00_AXI_arprot     (sc_arprot),
        .M00_AXI_arvalid    (sc_arvalid),
        .M00_AXI_arready    (sc_arready),

        .M00_AXI_rdata      (sc_rdata),
        .M00_AXI_rresp      (sc_rresp),
        .M00_AXI_rlast      (sc_rlast),
        .M00_AXI_rvalid     (sc_rvalid),
        .M00_AXI_rready     (sc_rready)
    );

    // Diagnostic: verify physical-to-local address mapping.
    integer sc_addr_prints = 0;

    always @(posedge axi_clk) begin
        if (axi_rstn && sc_arvalid && sc_arready &&
            sc_addr_prints < 4) begin
            $display("SC_M00_READ_ADDR=%08h", sc_araddr);
            sc_addr_prints = sc_addr_prints + 1;
        end
    end

    // Actual generated AXI BRAM Controller.
    design_1_axi_bram_ctrl_0_0 u_axi (
        .s_axi_aclk    (axi_clk),
        .s_axi_aresetn (axi_rstn),

        // AXI write channel disabled.
        .s_axi_awaddr  (13'd0),
        .s_axi_awlen   (8'd0),
        .s_axi_awsize  (3'd2),
        .s_axi_awburst (2'b01),
        .s_axi_awlock  (1'b0),
        .s_axi_awcache (4'd0),
        .s_axi_awprot  (3'd0),
        .s_axi_awvalid (1'b0),
        .s_axi_awready (),

        .s_axi_wdata   (32'd0),
        .s_axi_wstrb   (4'd0),
        .s_axi_wlast   (1'b0),
        .s_axi_wvalid  (1'b0),
        .s_axi_wready  (),
        .s_axi_bresp   (),
        .s_axi_bvalid  (),
        .s_axi_bready  (1'b1),

        // AXI read channel.
        .s_axi_araddr  (sc_araddr),
        .s_axi_arlen   (sc_arlen),
        .s_axi_arsize  (sc_arsize),
        .s_axi_arburst (sc_arburst),
        .s_axi_arlock  (sc_arlock),
        .s_axi_arcache (sc_arcache),
        .s_axi_arprot  (sc_arprot),
        .s_axi_arvalid (sc_arvalid),
        .s_axi_arready (sc_arready),

        .s_axi_rdata   (sc_rdata),
        .s_axi_rresp   (sc_rresp),
        .s_axi_rlast   (sc_rlast),
        .s_axi_rvalid  (sc_rvalid),
        .s_axi_rready  (sc_rready),

        // BRAM native port.
        .bram_rst_a    (b_rst),
        .bram_clk_a    (b_clk),
        .bram_en_a     (b_en),
        .bram_we_a     (b_we),
        .bram_addr_a   (b_addr),
        .bram_wrdata_a (b_wdata),
        .bram_rddata_a (b_rdata)
    );

    // Actual Xilinx true-dual-port BRAM.
    design_1_blk_mem_gen_0_0 u_real_bram (
        // ADC writer on Port A.
        .clka  (u_tb.adc_clk),
        .ena   (1'b1),
        .wea   ({4{u_tb.bram_we}}),
        .addra (u_tb.bram_addr),
        .dina  (u_tb.bram_data),
        .douta (),

        // AXI controller on Port B.
        .clkb  (b_clk),
        .enb   (b_en),
        .web   (b_we),
        .addrb ({19'd0, b_addr}),
        .dinb  (b_wdata),
        .doutb (b_rdata)
    );

    integer sent = 0;
    integer received = 0;
    integer mismatches = 0;
    integer i;

    // Check each AXI4 read-data handshake.
    always @(posedge axi_clk) begin
        if (axi_rstn && rvalid && rready) begin

            if (received >= 264)
                $fatal(1, "Unexpected extra AXI read");

            if (rresp !== 2'b00) begin
                $display("AXI RRESP error at %0d", received);
                mismatches = mismatches + 1;
            end

            if (rlast !== 1'b1) begin
                $display("Missing RLAST at %0d", received);
                mismatches = mismatches + 1;
            end

            if (rdata !== u_tb.memory[received]) begin
                if (mismatches < 10)
                    $display(
                        "MISMATCH word=%0d actual=%08h expected=%08h",
                        received, rdata, u_tb.memory[received]
                    );

                mismatches = mismatches + 1;
            end

            if (received < 4 || received == 263)
                $display(
                    "AXI_READ word=%0d offset=%0d data=%08h",
                    received, received*4, rdata
                );

            received = received + 1;
        end
    end

    initial begin
        wait (axi_rstn === 1'b1);
        wait (u_tb.packet_done === 1'b1);

        repeat (5) @(negedge axi_clk);

        $display("=== AXI BRAM CONTROLLER READBACK ===");

        // Send 264 AXI4 single-beat reads.
        for (i = 0; i < 264; i = i + 1) begin

            @(negedge axi_clk);
            araddr = 32'h40000000 + (i * 4);
            arvalid = 1'b1;

            // Hold VALID until address handshake.
            do begin
                @(posedge axi_clk);
            end while (arready !== 1'b1);

            @(negedge axi_clk);
            arvalid = 1'b0;

            sent = sent + 1;
        end

        wait (received == 264);

        repeat (5) @(posedge axi_clk);

        $display("AXI_REQUESTS=%0d", sent);
        $display("AXI_RESPONSES=%0d", received);
        $display("AXI_MISMATCHES=%0d", mismatches);

        if (sent != 264 || received != 264 || mismatches != 0)
            $fatal(1, "FAIL: AXI BRAM controller readback");

        $display("PASS: 264 AXI4 reads match VDIF packet");

        $finish;
    end

    initial begin
        #180000;
        $fatal(1, "TIMEOUT: AXI readback incomplete");
    end

endmodule


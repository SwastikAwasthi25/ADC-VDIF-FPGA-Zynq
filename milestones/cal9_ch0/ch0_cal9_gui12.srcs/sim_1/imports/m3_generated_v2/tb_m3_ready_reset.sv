
`timescale 1ns / 1ps

module tb_m3_ready_reset;

    reg clk = 0;
    reg clock_enabled = 1;

    always #4
        if (clock_enabled)
            clk = ~clk;

    reg rst_n = 0;
    reg frontend_ready = 0;
    reg [13:0] adc_raw_ch0 = 14'h0123;
    reg m_axis_tready = 0;

    wire [7:0] m_axis_tdata;
    wire m_axis_tvalid;
    wire capture_done;
    wire replay_done;
    wire [10:0] sample_count;

    integer saved_count;
    reg test_complete = 1'b0;

    adc_ch0_live_bridge dut (
        .clk(clk),
        .rst_n(rst_n),
        .frontend_ready(frontend_ready),
        .adc_raw_ch0(adc_raw_ch0),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .capture_done(capture_done),
        .replay_done(replay_done),
        .sample_count(sample_count)
    );

    initial begin
        repeat (4) @(negedge clk);

        rst_n = 1;
        frontend_ready = 1;

        repeat (12) @(negedge clk);

        if (sample_count < 4)
            $fatal(1, "FAIL: Capture did not start");

        $display("PASS: Capture started");

        frontend_ready = 0;

        repeat (2) @(negedge clk);

        if (sample_count !== 0)
            $fatal(1, "FAIL: Readiness loss did not reset buffer");

        $display("PASS: Readiness loss reset buffer");

        frontend_ready = 1;

        repeat (12) @(negedge clk);

        if (sample_count < 4)
            $fatal(1, "FAIL: Capture did not restart");

        $display("PASS: Capture restarted");

        saved_count = sample_count;
        clock_enabled = 0;

        #80;

        if (sample_count !== saved_count)
            $fatal(1, "FAIL: State changed without clock");

        $display("PASS: State held while clock stopped");

        clock_enabled = 1;

        repeat (3) @(negedge clk);

        if (sample_count <= saved_count)
            $fatal(1, "FAIL: Capture did not resume");

        $display("OBSERVATION: Capture resumed with ready held HIGH");
        $display("UNIT_TEST_COMPLETE");
	test_complete = 1'b1;
        $finish;
    end

    
initial begin
    #100000;
    if (!test_complete)
        $fatal(1, "FAIL: Simulation timeout");
    else
        $finish;
end


endmodule

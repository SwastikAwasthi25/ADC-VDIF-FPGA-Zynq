module adc14_axis_tap (
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 clk CLK" *)
    (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME clk, ASSOCIATED_BUSIF s_axis, FREQ_HZ 125000000" *)
    input wire clk,
    input  wire [13:0] s_axis_tdata,
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,

    output wire [13:0] sample_data,
    output wire        sample_valid
);

    // Existing rp_adc_capture produces one sample per ADC clock.
    // Its TREADY input does not throttle physical ADC sampling.
    //
    // The downstream one-shot frame buffer captures 1024 samples
    // and then stops accepting additional samples internally.
    //
    // This adapter does not provide backpressure or buffering.

    assign s_axis_tready = 1'b1;

    assign sample_data  = s_axis_tdata;
    assign sample_valid = s_axis_tvalid;

endmodule


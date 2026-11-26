module m25_pps_once (
    input  wire       clk,
    input  wire       rst_n,

    output wire [7:0] m_axis_tdata,
    output reg        m_axis_tvalid,
    input  wire       m_axis_tready
);

    reg sent;

    // Synthetic startup event, not GPS/UTC PPS.
    assign m_axis_tdata = 8'h00;

    always @(posedge clk) begin
        if (!rst_n) begin
            sent          <= 1'b0;
            m_axis_tvalid <= 1'b0;
        end else if (!sent) begin
            if (m_axis_tvalid && m_axis_tready) begin
                sent          <= 1'b1;
                m_axis_tvalid <= 1'b0;
            end else begin
                m_axis_tvalid <= 1'b1;
            end
        end else begin
            m_axis_tvalid <= 1'b0;
        end
    end

endmodule

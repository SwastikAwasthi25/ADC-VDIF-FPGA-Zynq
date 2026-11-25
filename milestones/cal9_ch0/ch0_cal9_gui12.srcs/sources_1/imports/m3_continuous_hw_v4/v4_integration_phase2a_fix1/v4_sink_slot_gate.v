`timescale 1ns / 1ps
// V4 Phase2A: pure ADC-domain gate; never start a new capture if both
// frame banks are owned by the PS. Status comes from the same-clock sink.
module v4_sink_slot_gate (
    input  wire [1:0] frame_ready,
    output wire       sink_slot_free
);
    assign sink_slot_free = ~(frame_ready[0] & frame_ready[1]);
endmodule
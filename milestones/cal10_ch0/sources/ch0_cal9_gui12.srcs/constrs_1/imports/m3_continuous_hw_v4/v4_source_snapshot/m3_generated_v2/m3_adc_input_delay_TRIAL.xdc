
# M3 TRIAL ADC input delays.
# Experimental only; not measured timing sign-off.

set ch01 [get_ports {adc_data_pins[0] adc_data_pins[1] adc_data_pins[2] adc_data_pins[3] adc_data_pins[4] adc_data_pins[5] adc_data_pins[6] adc_data_pins[7] adc_data_pins[8] adc_data_pins[9] adc_data_pins[10] adc_data_pins[11] adc_data_pins[12] adc_data_pins[13]}]

set ch23 [get_ports {adc_data_pins[14] adc_data_pins[15] adc_data_pins[16] adc_data_pins[17] adc_data_pins[18] adc_data_pins[19] adc_data_pins[20] adc_data_pins[21] adc_data_pins[22] adc_data_pins[23] adc_data_pins[24] adc_data_pins[25] adc_data_pins[26] adc_data_pins[27]}]

set c01 [get_clocks adc_clk0]
set c23 [get_clocks adc_clk1]

set_input_delay -clock $c01 -min 2.0 $ch01
set_input_delay -clock $c01 -max 2.6 $ch01
set_input_delay -clock $c01 -clock_fall -add_delay -min 2.0 $ch01
set_input_delay -clock $c01 -clock_fall -add_delay -max 2.6 $ch01

set_input_delay -clock $c23 -min 2.0 $ch23
set_input_delay -clock $c23 -max 2.6 $ch23
set_input_delay -clock $c23 -clock_fall -add_delay -min 2.0 $ch23
set_input_delay -clock $c23 -clock_fall -add_delay -max 2.6 $ch23

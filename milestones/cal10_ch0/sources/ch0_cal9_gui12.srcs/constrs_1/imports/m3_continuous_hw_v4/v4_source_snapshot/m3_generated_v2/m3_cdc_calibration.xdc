# M3 only: calibration_ready to first CDC synchronizer stage
# Stage 0 and 1 ASYNC_REG=TRUE; stage 0 has no bypass
set_false_path -from [get_pins {design_1_i/m3_adc_spi_ch0_bridge_0/inst/u_m3_adapter/u_frontend/u_adc_clocks/u_idelay_reset/calibration_ready_reg_reg/C}] -to [get_pins {design_1_i/m3_adc_spi_ch0_bridge_0/inst/u_m3_adapter/cal_sync_reg[0]/D}]

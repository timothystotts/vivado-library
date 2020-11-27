# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"

}

proc update_PARAM_VALUE.AXI_LITE_SPI_BASEADDR { PARAM_VALUE.AXI_LITE_SPI_BASEADDR } {
	# Procedure called to update AXI_LITE_SPI_BASEADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.AXI_LITE_SPI_BASEADDR { PARAM_VALUE.AXI_LITE_SPI_BASEADDR } {
	# Procedure called to validate AXI_LITE_SPI_BASEADDR
	return true
}

proc update_PARAM_VALUE.AXI_LITE_SPI_HIGHADDR { PARAM_VALUE.AXI_LITE_SPI_HIGHADDR } {
	# Procedure called to update AXI_LITE_SPI_HIGHADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.AXI_LITE_SPI_HIGHADDR { PARAM_VALUE.AXI_LITE_SPI_HIGHADDR } {
	# Procedure called to validate AXI_LITE_SPI_HIGHADDR
	return true
}

proc update_PARAM_VALUE.PMOD { PARAM_VALUE.PMOD } {
	# Procedure called to update PMOD when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.PMOD { PARAM_VALUE.PMOD } {
	# Procedure called to validate PMOD
	return true
}

proc update_PARAM_VALUE.USE_BOARD_FLOW { PARAM_VALUE.USE_BOARD_FLOW } {
	# Procedure called to update USE_BOARD_FLOW when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.USE_BOARD_FLOW { PARAM_VALUE.USE_BOARD_FLOW } {
	# Procedure called to validate USE_BOARD_FLOW
	return true
}



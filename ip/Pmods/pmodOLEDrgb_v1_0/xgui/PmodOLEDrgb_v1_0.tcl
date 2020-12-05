# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"

}

proc update_PARAM_VALUE.C_AXI_LITE_GPIO_ADDR_WIDTH { PARAM_VALUE.C_AXI_LITE_GPIO_ADDR_WIDTH } {
	# Procedure called to update C_AXI_LITE_GPIO_ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_AXI_LITE_GPIO_ADDR_WIDTH { PARAM_VALUE.C_AXI_LITE_GPIO_ADDR_WIDTH } {
	# Procedure called to validate C_AXI_LITE_GPIO_ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.C_AXI_LITE_GPIO_DATA_WIDTH { PARAM_VALUE.C_AXI_LITE_GPIO_DATA_WIDTH } {
	# Procedure called to update C_AXI_LITE_GPIO_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_AXI_LITE_GPIO_DATA_WIDTH { PARAM_VALUE.C_AXI_LITE_GPIO_DATA_WIDTH } {
	# Procedure called to validate C_AXI_LITE_GPIO_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.C_AXI_LITE_SPI_ADDR_WIDTH { PARAM_VALUE.C_AXI_LITE_SPI_ADDR_WIDTH } {
	# Procedure called to update C_AXI_LITE_SPI_ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_AXI_LITE_SPI_ADDR_WIDTH { PARAM_VALUE.C_AXI_LITE_SPI_ADDR_WIDTH } {
	# Procedure called to validate C_AXI_LITE_SPI_ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.C_AXI_LITE_SPI_DATA_WIDTH { PARAM_VALUE.C_AXI_LITE_SPI_DATA_WIDTH } {
	# Procedure called to update C_AXI_LITE_SPI_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_AXI_LITE_SPI_DATA_WIDTH { PARAM_VALUE.C_AXI_LITE_SPI_DATA_WIDTH } {
	# Procedure called to validate C_AXI_LITE_SPI_DATA_WIDTH
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

proc update_PARAM_VALUE.C_AXI_LITE_GPIO_BASEADDR { PARAM_VALUE.C_AXI_LITE_GPIO_BASEADDR } {
	# Procedure called to update C_AXI_LITE_GPIO_BASEADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_AXI_LITE_GPIO_BASEADDR { PARAM_VALUE.C_AXI_LITE_GPIO_BASEADDR } {
	# Procedure called to validate C_AXI_LITE_GPIO_BASEADDR
	return true
}

proc update_PARAM_VALUE.C_AXI_LITE_SPI_BASEADDR { PARAM_VALUE.C_AXI_LITE_SPI_BASEADDR } {
	# Procedure called to update C_AXI_LITE_SPI_BASEADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_AXI_LITE_SPI_BASEADDR { PARAM_VALUE.C_AXI_LITE_SPI_BASEADDR } {
	# Procedure called to validate C_AXI_LITE_SPI_BASEADDR
	return true
}

proc update_PARAM_VALUE.C_AXI_LITE_GPIO_HIGHADDR { PARAM_VALUE.C_AXI_LITE_GPIO_HIGHADDR } {
	# Procedure called to update C_AXI_LITE_GPIO_HIGHADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_AXI_LITE_GPIO_HIGHADDR { PARAM_VALUE.C_AXI_LITE_GPIO_HIGHADDR } {
	# Procedure called to validate C_AXI_LITE_GPIO_HIGHADDR
	return true
}

proc update_PARAM_VALUE.C_AXI_LITE_SPI_HIGHADDR { PARAM_VALUE.C_AXI_LITE_SPI_HIGHADDR } {
	# Procedure called to update C_AXI_LITE_SPI_HIGHADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_AXI_LITE_SPI_HIGHADDR { PARAM_VALUE.C_AXI_LITE_SPI_HIGHADDR } {
	# Procedure called to validate C_AXI_LITE_SPI_HIGHADDR
	return true
}


proc update_MODELPARAM_VALUE.C_AXI_LITE_GPIO_DATA_WIDTH { MODELPARAM_VALUE.C_AXI_LITE_GPIO_DATA_WIDTH PARAM_VALUE.C_AXI_LITE_GPIO_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_AXI_LITE_GPIO_DATA_WIDTH}] ${MODELPARAM_VALUE.C_AXI_LITE_GPIO_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.C_AXI_LITE_GPIO_ADDR_WIDTH { MODELPARAM_VALUE.C_AXI_LITE_GPIO_ADDR_WIDTH PARAM_VALUE.C_AXI_LITE_GPIO_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_AXI_LITE_GPIO_ADDR_WIDTH}] ${MODELPARAM_VALUE.C_AXI_LITE_GPIO_ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.C_AXI_LITE_SPI_DATA_WIDTH { MODELPARAM_VALUE.C_AXI_LITE_SPI_DATA_WIDTH PARAM_VALUE.C_AXI_LITE_SPI_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_AXI_LITE_SPI_DATA_WIDTH}] ${MODELPARAM_VALUE.C_AXI_LITE_SPI_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.C_AXI_LITE_SPI_ADDR_WIDTH { MODELPARAM_VALUE.C_AXI_LITE_SPI_ADDR_WIDTH PARAM_VALUE.C_AXI_LITE_SPI_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_AXI_LITE_SPI_ADDR_WIDTH}] ${MODELPARAM_VALUE.C_AXI_LITE_SPI_ADDR_WIDTH}
}


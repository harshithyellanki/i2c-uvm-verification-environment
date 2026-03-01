# questa_compile_regfile.do
if {[file exists work]} {vdel -all}
vlib work
vmap work work

set SV_OPTS "+acc"

vlog -sv $SV_OPTS -work work ../tb/i2c_if_rf.sv
vlog -sv $SV_OPTS -work work ../rtl/i2c_slave_regfile_dut.sv
vlog -sv $SV_OPTS -work work ../tb/i2c_assertions.sv
vlog -sv $SV_OPTS -work work ../tb/uvm/i2c_pkg_regfile.sv
vlog -sv $SV_OPTS -work work ../tb/top_tb_regfile.sv

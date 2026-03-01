# questa_run_regfile_gui.do
do questa_compile_regfile.do

vsim -voptargs=+acc work.top_tb_regfile -classdebug -uvmcontrol=all

view wave
delete wave *

add wave -divider "TOP"
add wave sim:/top_tb_regfile/tb_clk
add wave sim:/top_tb_regfile/reset_n

add wave -divider "I2C_BUS"
add wave sim:/top_tb_regfile/i2c/scl
add wave sim:/top_tb_regfile/i2c/sda
add wave sim:/top_tb_regfile/i2c/m_scl
add wave sim:/top_tb_regfile/i2c/m_sda_oe
add wave sim:/top_tb_regfile/i2c/s_sda_oe

add wave -divider "DUT"
add wave -r sim:/top_tb_regfile/dut/*

add wave -divider "SVA"
add wave -r sim:/top_tb_regfile/sva/*

run -all
wave zoom full

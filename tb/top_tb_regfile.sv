`timescale 1ns/1ps
module top_tb_regfile;

  import uvm_pkg::*;
  import i2c_pkg_regfile::*;

  logic tb_clk;
  initial tb_clk = 0;
  always #5ns tb_clk = ~tb_clk;

  logic reset_n;

  i2c_if_rf #(.T_HIGH(2500ns), .T_LOW(2500ns)) i2c (tb_clk);

  i2c_slave_regfile_dut #(.I2C_SLAVE_ADDR(7'h42)) dut (
    .reset_n(reset_n),
    .scl(i2c.scl),
    .sda(i2c.sda)
  );

  // Connect DUT open-drain pull-low to interface
  always_comb i2c.s_sda_oe = dut.sda_drive_low;

  initial begin
    reset_n = 1'b0;
    repeat (5) @(posedge tb_clk);
    reset_n = 1'b1;
  end

  i2c_assertions sva (
    .scl(i2c.scl),
    .sda(i2c.sda),
    .reset_n(reset_n)
  );

  initial begin
    uvm_config_db#(i2c_vif_t)::set(null, "uvm_test_top.env.agt", "vif", i2c);
    run_test("i2c_test");
  end

endmodule

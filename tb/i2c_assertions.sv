`timescale 1ns/1ps
module i2c_assertions (
  input logic scl,
  input tri1  sda,
  input logic reset_n
);
  logic sda_high_q;
  always_ff @(posedge scl or negedge reset_n) begin
    if (!reset_n) sda_high_q <= 1'b1;
    else          sda_high_q <= sda;
  end

  // Check that any SDA change during SCL high is consistent with START/STOP
  property p_sda_change_ok;
    @(negedge scl) disable iff (!reset_n)
      (sda_high_q == sda) ||
      ((sda_high_q == 1'b1) && (sda == 1'b0)) ||
      ((sda_high_q == 1'b0) && (sda == 1'b1));
  endproperty
  a_sda_change_ok: assert property (p_sda_change_ok)
    else $error("[I2C][SVA] SDA changed during SCL high (not START/STOP)");

  // SCL known
  property p_scl_known;
    @(posedge scl or negedge scl) disable iff (!reset_n) !$isunknown(scl);
  endproperty
  a_scl_known: assert property (p_scl_known)
    else $error("[I2C][SVA] SCL unknown");

  c_start: cover property (@(negedge sda) disable iff(!reset_n) (scl===1'b1));
  c_stop : cover property (@(posedge sda) disable iff(!reset_n) (scl===1'b1));
endmodule

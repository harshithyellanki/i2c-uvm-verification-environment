`timescale 1ns/1ps
interface i2c_if_rf #(time T_HIGH = 2500ns, time T_LOW = 2500ns) (input logic tb_clk);
  tri1 sda;
  logic scl;

  logic m_sda_oe;
  logic m_scl;
  logic s_sda_oe;

  assign sda = (m_sda_oe || s_sda_oe) ? 1'b0 : 1'bz;
  assign scl = m_scl;

  task automatic drive_sda_low(); m_sda_oe = 1'b1; endtask
  task automatic release_sda();   m_sda_oe = 1'b0; endtask
  task automatic drive_scl(bit v); m_scl = v; endtask

  task automatic t_high(); #(T_HIGH); endtask
  task automatic t_low();  #(T_LOW);  endtask

  task automatic idle_bus();
    release_sda();
    drive_scl(1'b1);
    #(T_HIGH/5);
  endtask

  task automatic i2c_start();
    idle_bus();
    #(T_HIGH/10);
    drive_sda_low();
    #(T_HIGH/5);
    drive_scl(1'b0);
    t_low();
  endtask

  task automatic i2c_rep_start();
    drive_scl(1'b0);
    release_sda();
    t_low();
    drive_scl(1'b1);
    #(T_HIGH/4);
    drive_sda_low();
    #(T_HIGH/4);
    drive_scl(1'b0);
    t_low();
  endtask

  task automatic i2c_stop();
    drive_scl(1'b0);
    drive_sda_low();
    t_low();
    drive_scl(1'b1);
    #(T_HIGH/4);
    release_sda();
    #(T_HIGH*3/4);
  endtask

  task automatic send_bit(bit b);
    drive_scl(1'b0);
    if (b) release_sda(); else drive_sda_low();
    t_low();
    drive_scl(1'b1);
    t_high();
  endtask

  task automatic read_bit(output bit b);
    drive_scl(1'b0);
    release_sda();
    t_low();
    drive_scl(1'b1);
    #(T_HIGH/2);
    b = sda;
    #(T_HIGH/2);
  endtask

  task automatic send_byte(input byte unsigned data);
    for (int i=7; i>=0; i--) send_bit(data[i]);
  endtask

  task automatic read_byte(output byte unsigned data);
    bit b;
    data = 8'h00;
    for (int i=7; i>=0; i--) begin
      read_bit(b);
      data[i] = b;
    end
  endtask

  task automatic read_ack(output bit ack_n);
    bit b;
    read_bit(b);
    ack_n = b;
  endtask

  task automatic drive_master_ack(input bit ack_n);
    send_bit(ack_n);
  endtask

  initial begin
    m_sda_oe = 1'b0;
    m_scl    = 1'b1;
  //  s_sda_oe = 1'b0;
  end

  modport master (
    input  tb_clk,
    input  sda, input scl,
    output m_sda_oe, output m_scl,
    input  s_sda_oe,
    import drive_sda_low, release_sda, drive_scl,
           idle_bus, i2c_start, i2c_rep_start, i2c_stop,
           send_bit, read_bit, send_byte, read_byte,
           read_ack, drive_master_ack
  );

  modport slave (
    input  sda, input scl,
    output s_sda_oe
  );
endinterface

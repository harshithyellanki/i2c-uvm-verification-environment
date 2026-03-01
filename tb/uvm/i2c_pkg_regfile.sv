// `timescale 1ns/1ps
// package i2c_pkg_regfile;

//   import uvm_pkg::*;
//   `include "uvm_macros.svh"

//   typedef enum {I2C_WRITE, I2C_READ} i2c_dir_e;
//   typedef virtual i2c_if_rf.master i2c_vif_t;

//   class i2c_item extends uvm_sequence_item;
//     rand bit [6:0] addr;
//     rand i2c_dir_e dir;
//     rand bit [7:0] reg_ptr;
//     rand bit [7:0] wdata;

//          bit [7:0] rdata;
//          bit       addr_ack;
//          bit       reg_ack;
//          bit       data_ack;

//     constraint c_addr   { addr inside {[7'h08:7'h77]}; }
//     constraint c_dir    { dir dist {I2C_WRITE:=60, I2C_READ:=40}; }
//     constraint c_regptr { reg_ptr inside {[8'h00:8'hFF]}; }
//     constraint c_wdata  { wdata inside {[8'h00:8'hFF]}; }

//     `uvm_object_utils_begin(i2c_item)
//       `uvm_field_int(addr, UVM_ALL_ON)
//       `uvm_field_enum(i2c_dir_e, dir, UVM_ALL_ON)
//       `uvm_field_int(reg_ptr, UVM_ALL_ON)
//       `uvm_field_int(wdata, UVM_ALL_ON)
//       `uvm_field_int(rdata, UVM_ALL_ON | UVM_NOCOMPARE)
//       `uvm_field_int(addr_ack, UVM_ALL_ON)
//       `uvm_field_int(reg_ack,  UVM_ALL_ON)
//       `uvm_field_int(data_ack, UVM_ALL_ON)
//     `uvm_object_utils_end

//     function new(string name="i2c_item");
//       super.new(name);
//       rdata = '0;
//       addr_ack = 0;
//       reg_ack  = 0;
//       data_ack = 0;
//     endfunction
//   endclass

//   class i2c_sequencer extends uvm_sequencer #(i2c_item);
//     `uvm_component_utils(i2c_sequencer)
//     function new(string n, uvm_component p); super.new(n,p); endfunction
//   endclass

//   class i2c_driver extends uvm_driver #(i2c_item);
//     `uvm_component_utils(i2c_driver)

//     i2c_vif_t vif;
//     uvm_analysis_port #(i2c_item) ap;

//     int unsigned inter_tx_idle_cycles = 2;

//     function new(string n, uvm_component p);
//       super.new(n,p);
//       ap = new("ap", this);
//     endfunction

//     function void build_phase(uvm_phase phase);
//       super.build_phase(phase);
//       if (!uvm_config_db#(i2c_vif_t)::get(this, "", "vif", vif))
//         `uvm_fatal("NOVIF", "i2c_driver: no vif")
//     endfunction

//     task run_phase(uvm_phase phase);
//       i2c_item tr;
//       vif.idle_bus();
//       forever begin
//         seq_item_port.get_next_item(tr);
//         drive_transaction(tr);
//         ap.write(tr);               // publish what actually happened
//         seq_item_port.item_done();
//         repeat (inter_tx_idle_cycles) @(posedge vif.tb_clk);
//       end
//     endtask

//     task automatic drive_transaction(ref i2c_item tr);
//       bit ack_n;
//       byte unsigned addr_w, addr_r, rx;

//       addr_w = {tr.addr, 1'b0};
//       addr_r = {tr.addr, 1'b1};

//       // Phase 1: write address + reg_ptr
//       vif.i2c_start();
//       vif.send_byte(addr_w);
//       vif.read_ack(ack_n);
//       tr.addr_ack = (ack_n == 0);
//       if (!tr.addr_ack) begin
//         vif.i2c_stop();
//         return;
//       end

//       vif.send_byte(tr.reg_ptr);
//       vif.read_ack(ack_n);
//       tr.reg_ack = (ack_n == 0);
//       if (!tr.reg_ack) begin
//         vif.i2c_stop();
//         return;
//       end

//       if (tr.dir == I2C_WRITE) begin
//         vif.send_byte(tr.wdata);
//         vif.read_ack(ack_n);
//         tr.data_ack = (ack_n == 0);
//         vif.i2c_stop();
//       end else begin
//         vif.i2c_rep_start();
//         vif.send_byte(addr_r);
//         vif.read_ack(ack_n); // ignore for now

//         vif.read_byte(rx);
//         tr.rdata = rx;

//         // single-byte read
//         vif.drive_master_ack(1'b1);
//         tr.data_ack = 0;

//         vif.i2c_stop();
//       end
//     endtask
//   endclass

//   class i2c_scoreboard extends uvm_component;
//     `uvm_component_utils(i2c_scoreboard)

//     uvm_analysis_imp #(i2c_item, i2c_scoreboard) imp;

//     bit [6:0] dut_addr = 7'h42;
//     byte unsigned model [0:255];

//     function new(string n, uvm_component p);
//       super.new(n,p);
//       imp = new("imp", this);
//       foreach (model[i]) model[i] = 8'h00;
//     endfunction

//     function void write(i2c_item tr);
//       if (!tr.addr_ack) return;
//       if (tr.addr != dut_addr) return;
//       if (!tr.reg_ack) return;

//       if (tr.dir == I2C_WRITE) begin
//         if (!tr.data_ack) begin
//           `uvm_error("SB", $sformatf("WRITE NACK at reg 0x%02h", tr.reg_ptr))
//         end else begin
//           model[tr.reg_ptr] = tr.wdata;
//           `uvm_info("SB", $sformatf("WRITE OK reg[0x%02h]=0x%02h", tr.reg_ptr, tr.wdata), UVM_LOW)
//         end
//       end else begin
//         if (tr.rdata !== model[tr.reg_ptr]) begin
//           `uvm_error("SB", $sformatf("READ MISMATCH reg[0x%02h] got=0x%02h exp=0x%02h",
//                                      tr.reg_ptr, tr.rdata, model[tr.reg_ptr]))
//         end else begin
//           `uvm_info("SB", $sformatf("READ OK reg[0x%02h]=0x%02h", tr.reg_ptr, tr.rdata), UVM_LOW)
//         end
//       end
//     endfunction
//   endclass

// class i2c_coverage extends uvm_subscriber #(i2c_item);
//   `uvm_component_utils(i2c_coverage)

//   // Sampling variables (must exist before covergroup in Questa)
//   bit [6:0] cur_addr;
//   bit       cur_dir;
//   bit       cur_addr_ack;
//   bit [7:0] cur_reg;
//   bit [7:0] cur_data;

//   // Eventless covergroup; we sample() manually from write()
//   covergroup cg;
//     option.per_instance = 1;

//     addr_cp: coverpoint cur_addr {
//       bins low  = {[7'h08:7'h1F]};
//       bins mid  = {[7'h20:7'h3F]};
//       bins high = {[7'h40:7'h77]};
//       bins dut  = {7'h42};
//     }

//     dir_cp: coverpoint cur_dir { bins wr = {0}; bins rd = {1}; }

//     addr_ack_cp: coverpoint cur_addr_ack { bins ack = {1}; bins nack = {0}; }

//     reg_cp: coverpoint cur_reg {
//       bins zero = {8'h00};
//       bins ff   = {8'hFF};
//       bins mid[] = {[8'h01:8'hFE]};
//     }

//     data_cp: coverpoint cur_data {
//       bins zero = {8'h00};
//       bins ff   = {8'hFF};
//       bins mid[] = {[8'h01:8'hFE]};
//     }

//     cross addr_cp, dir_cp, addr_ack_cp;
//   endgroup

//   function new(string name, uvm_component parent);
//     super.new(name, parent);
//     cg = new(); // IMPORTANT: construct covergroup here (Questa requirement)
//   endfunction

//   // UVM-1.1d picky: base method is write(T t) and it wants arg name 't'
//   virtual function void write(i2c_item t);
//     cur_addr     = t.addr;
//     cur_dir      = (t.dir == I2C_READ);
//     cur_addr_ack = t.addr_ack;
//     cur_reg      = t.reg_ptr;
//     cur_data     = (t.dir == I2C_WRITE) ? t.wdata : t.rdata;
//     cg.sample();
//   endfunction

// endclass



//   class i2c_agent extends uvm_component;
//     `uvm_component_utils(i2c_agent)

//     i2c_sequencer seqr;
//     i2c_driver    drv;

//     i2c_vif_t vif;
//     uvm_analysis_port #(i2c_item) ap;

//     function new(string n, uvm_component p);
//       super.new(n,p);
//       ap = new("ap", this);
//     endfunction

//     function void build_phase(uvm_phase phase);
//       super.build_phase(phase);
//       if (!uvm_config_db#(i2c_vif_t)::get(this, "", "vif", vif))
//         `uvm_fatal("NOVIF", "i2c_agent: no vif")

//       seqr = i2c_sequencer::type_id::create("seqr", this);
//       drv  = i2c_driver   ::type_id::create("drv",  this);

//       uvm_config_db#(i2c_vif_t)::set(this, "drv", "vif", vif);
//     endfunction

//     function void connect_phase(uvm_phase phase);
//       super.connect_phase(phase);
//       drv.seq_item_port.connect(seqr.seq_item_export);
//       drv.ap.connect(ap);
//     endfunction
//   endclass

//   class i2c_env extends uvm_env;
//     `uvm_component_utils(i2c_env)

//     i2c_agent     agt;
//     i2c_scoreboard sb;
//     i2c_coverage   cov;

//     function new(string n, uvm_component p); super.new(n,p); endfunction

//     function void build_phase(uvm_phase phase);
//       super.build_phase(phase);
//       agt = i2c_agent::type_id::create("agt", this);
//       sb  = i2c_scoreboard::type_id::create("sb", this);
//       cov = i2c_coverage::type_id::create("cov", this);
//     endfunction

//     function void connect_phase(uvm_phase phase);
//       super.connect_phase(phase);
//       agt.ap.connect(sb.imp);
//       agt.ap.connect(cov.analysis_export);
//     endfunction
//   endclass

//   class i2c_base_seq extends uvm_sequence #(i2c_item);
//     `uvm_object_utils(i2c_base_seq)
//     function new(string n="i2c_base_seq"); super.new(n); endfunction
//   endclass

//   class i2c_directed_seq extends i2c_base_seq;
//     `uvm_object_utils(i2c_directed_seq)
//     function new(string n="i2c_directed_seq"); super.new(n); endfunction

//     task body();
//       i2c_item tr;

//       tr = i2c_item::type_id::create("wr10");
//       void'(tr.randomize() with { addr==7'h42; dir==I2C_WRITE; reg_ptr==8'h10; wdata==8'h3C; });
//       start_item(tr); finish_item(tr);

//       tr = i2c_item::type_id::create("rd10");
//       void'(tr.randomize() with { addr==7'h42; dir==I2C_READ; reg_ptr==8'h10; });
//       start_item(tr); finish_item(tr);

//       tr = i2c_item::type_id::create("nack_addr");
//       void'(tr.randomize() with { addr==7'h55; dir==I2C_WRITE; reg_ptr==8'h00; wdata==8'hAA; });
//       start_item(tr); finish_item(tr);
//     endtask
//   endclass

//   class i2c_random_seq extends i2c_base_seq;
//     `uvm_object_utils(i2c_random_seq)
//     rand int unsigned n_trans;
//     constraint c_n { n_trans inside {[50:150]}; }
//     function new(string n="i2c_random_seq"); super.new(n); endfunction

//     task body();
//       i2c_item tr;
//       for (int i=0;i<n_trans;i++) begin
//         tr = i2c_item::type_id::create($sformatf("tr_%0d", i));
//         void'(tr.randomize() with {
//           //addr dist { 7'h42 := 80, [7'h08:7'h77] := 20 };
// 		addr dist { 7'h42 := 100, [7'h08:7'h77] := 0 };
//           reg_ptr dist { [8'h00:8'h0F] := 30, [8'h10:8'hEF] := 60, [8'hF0:8'hFF] := 10 };
//           wdata dist { 8'h00 := 10, 8'hFF := 10, [8'h01:8'hFE] := 80 };
//         });
//         start_item(tr); finish_item(tr);
//       end
//     endtask
//   endclass

//   // class i2c_test extends uvm_test;
//   //   `uvm_component_utils(i2c_test)
//   //   i2c_env env;
//   //   function new(string n, uvm_component p); super.new(n,p); endfunction

//   //   function void build_phase(uvm_phase phase);
//   //     super.build_phase(phase);
//   //     env = i2c_env::type_id::create("env", this);
//   //   endfunction

//   //   task run_phase(uvm_phase phase);
//   //     i2c_directed_seq dseq;
//   //     i2c_random_seq rseq;
//   //     phase.raise_objection(this);
//   //     dseq = i2c_directed_seq::type_id::create("dseq");
//   //     rseq = i2c_random_seq::type_id::create("rseq");
//   //     dseq.start(env.agt.seqr);
//   //     rseq.start(env.agt.seqr);
//   //     phase.drop_objection(this);
//   //   endtask
//   // endclass


//   class i2c_test extends uvm_test;
//     `uvm_component_utils(i2c_test)
//     i2c_env env;

//     function new(string n, uvm_component p); super.new(n,p); endfunction

//     function void build_phase(uvm_phase phase);
//       super.build_phase(phase);
//       env = i2c_env::type_id::create("env", this);
//     endfunction

//     // --- ADDED DRAIN TIME HERE ---
//     function void end_of_elaboration_phase(uvm_phase phase);
//       super.end_of_elaboration_phase(phase);
//       // Set a 10 microsecond drain time. 
//       // This ensures the last random transaction is fully visible on the wave.
//       uvm_test_done.set_drain_time(this, 10us);
//     endfunction

//     task run_phase(uvm_phase phase);
//      //i2c_directed_seq dseq;
//       i2c_random_seq rseq;
//       phase.raise_objection(this);
      
//      // dseq = i2c_directed_seq::type_id::create("dseq");
//       rseq = i2c_random_seq::type_id::create("rseq");
      
//      // dseq.start(env.agt.seqr);
//       rseq.start(env.agt.seqr);
      
//       phase.drop_objection(this);
//     endtask
//   endclass

// endpackage

//-------------------------------------------------------------------------------------------

`timescale 1ns/1ps
package i2c_pkg_regfile;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  typedef enum {I2C_WRITE, I2C_READ} i2c_dir_e;
  typedef virtual i2c_if_rf.master i2c_vif_t;

  // --- Transaction Item ---
  class i2c_item extends uvm_sequence_item;
    rand bit [6:0] addr;
    rand i2c_dir_e dir;
    rand bit [7:0] reg_ptr;
    rand bit [7:0] wdata;

         bit [7:0] rdata;
         bit       addr_ack;
         bit       reg_ack;
         bit       data_ack;

    constraint c_addr   { addr inside {[7'h08:7'h77]}; }
    constraint c_dir    { dir dist {I2C_WRITE:=60, I2C_READ:=40}; }
    constraint c_regptr { reg_ptr inside {[8'h00:8'hFF]}; }
    constraint c_wdata  { wdata inside {[8'h00:8'hFF]}; }

    `uvm_object_utils_begin(i2c_item)
      `uvm_field_int(addr, UVM_ALL_ON)
      `uvm_field_enum(i2c_dir_e, dir, UVM_ALL_ON)
      `uvm_field_int(reg_ptr, UVM_ALL_ON)
      `uvm_field_int(wdata, UVM_ALL_ON)
      `uvm_field_int(rdata, UVM_ALL_ON | UVM_NOCOMPARE)
      `uvm_field_int(addr_ack, UVM_ALL_ON)
      `uvm_field_int(reg_ack,  UVM_ALL_ON)
      `uvm_field_int(data_ack, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name="i2c_item");
      super.new(name);
      rdata = '0;
      addr_ack = 0;
      reg_ack  = 0;
      data_ack = 0;
    endfunction
  endclass

  // --- Sequencer ---
  class i2c_sequencer extends uvm_sequencer #(i2c_item);
    `uvm_component_utils(i2c_sequencer)
    function new(string n, uvm_component p); super.new(n,p); endfunction
  endclass

  // --- Driver ---
  class i2c_driver extends uvm_driver #(i2c_item);
    `uvm_component_utils(i2c_driver)

    i2c_vif_t vif;
    uvm_analysis_port #(i2c_item) ap;
    int unsigned inter_tx_idle_cycles = 2;

    function new(string n, uvm_component p);
      super.new(n,p);
      ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(i2c_vif_t)::get(this, "", "vif", vif))
        `uvm_fatal("NOVIF", "i2c_driver: no vif")
    endfunction

    task run_phase(uvm_phase phase);
      i2c_item tr;
      vif.idle_bus();
      forever begin
        seq_item_port.get_next_item(tr);
        drive_transaction(tr);
        ap.write(tr);
        seq_item_port.item_done();
        repeat (inter_tx_idle_cycles) @(posedge vif.tb_clk);
      end
    endtask

    task automatic drive_transaction(ref i2c_item tr);
      bit ack_n;
      byte unsigned addr_w, addr_r, rx;
      addr_w = {tr.addr, 1'b0};
      addr_r = {tr.addr, 1'b1};

      vif.i2c_start();
      vif.send_byte(addr_w);
      vif.read_ack(ack_n);
      tr.addr_ack = (ack_n == 0);
      if (!tr.addr_ack) begin vif.i2c_stop(); return; end

      vif.send_byte(tr.reg_ptr);
      vif.read_ack(ack_n);
      tr.reg_ack = (ack_n == 0);
      if (!tr.reg_ack) begin vif.i2c_stop(); return; end

      if (tr.dir == I2C_WRITE) begin
        vif.send_byte(tr.wdata);
        vif.read_ack(ack_n);
        tr.data_ack = (ack_n == 0);
        vif.i2c_stop();
      end else begin
        vif.i2c_rep_start();
        vif.send_byte(addr_r);
        vif.read_ack(ack_n);
        vif.read_byte(rx);
        tr.rdata = rx;
        vif.drive_master_ack(1'b1);
        tr.data_ack = 0;
        vif.i2c_stop();
      end
    endtask
  endclass

  // --- Scoreboard ---
  class i2c_scoreboard extends uvm_component;
    `uvm_component_utils(i2c_scoreboard)
    uvm_analysis_imp #(i2c_item, i2c_scoreboard) imp;
    bit [6:0] dut_addr = 7'h42;
    byte unsigned model [0:255];

    function new(string n, uvm_component p);
      super.new(n,p);
      imp = new("imp", this);
      foreach (model[i]) model[i] = 8'h00;
    endfunction

    function void write(i2c_item tr);
      if (!tr.addr_ack || tr.addr != dut_addr || !tr.reg_ack) return;
      if (tr.dir == I2C_WRITE) begin
        if (tr.data_ack) model[tr.reg_ptr] = tr.wdata;
        `uvm_info("SB", $sformatf("WRITE %s reg[0x%02h]=0x%02h", tr.data_ack ? "OK" : "NACK", tr.reg_ptr, tr.wdata), UVM_LOW)
      end else begin
        if (tr.rdata !== model[tr.reg_ptr])
          `uvm_error("SB", $sformatf("READ MISMATCH reg[0x%02h] got=0x%02h exp=0x%02h", tr.reg_ptr, tr.rdata, model[tr.reg_ptr]))
        else
          `uvm_info("SB", $sformatf("READ OK reg[0x%02h]=0x%02h", tr.reg_ptr, tr.rdata), UVM_LOW)
      end
    endfunction
  endclass

  // --- Coverage ---
  class i2c_coverage extends uvm_subscriber #(i2c_item);
    `uvm_component_utils(i2c_coverage)
    bit [6:0] cur_addr;
    bit       cur_dir;
    bit       cur_addr_ack;
    bit [7:0] cur_reg;
    bit [7:0] cur_data;

    covergroup cg;
      option.per_instance = 1;
      addr_cp: coverpoint cur_addr { bins dut = {7'h42}; bins others = default; }
      dir_cp:  coverpoint cur_dir  { bins wr = {0}; bins rd = {1}; }
      reg_cp:  coverpoint cur_reg  { bins range[8] = {[8'h00:8'hFF]}; }
    endgroup

    function new(string name, uvm_component parent);
      super.new(name, parent);
      cg = new();
    endfunction

    virtual function void write(i2c_item t);
      cur_addr = t.addr; cur_dir = (t.dir == I2C_READ);
      cur_addr_ack = t.addr_ack; cur_reg = t.reg_ptr;
      cur_data = (t.dir == I2C_WRITE) ? t.wdata : t.rdata;
      cg.sample();
    endfunction
  endclass

  // --- Agent ---
  class i2c_agent extends uvm_component;
    `uvm_component_utils(i2c_agent)
    i2c_sequencer seqr;
    i2c_driver    drv;
    i2c_vif_t vif;
    uvm_analysis_port #(i2c_item) ap;

    function new(string n, uvm_component p); super.new(n,p); ap = new("ap", this); endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      seqr = i2c_sequencer::type_id::create("seqr", this);
      drv  = i2c_driver::type_id::create("drv", this);
      if (!uvm_config_db#(i2c_vif_t)::get(this, "", "vif", vif)) `uvm_fatal("NOVIF", "No vif")
      uvm_config_db#(i2c_vif_t)::set(this, "drv", "vif", vif);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      drv.seq_item_port.connect(seqr.seq_item_export);
      drv.ap.connect(ap);
    endfunction
  endclass

  // --- Environment ---
  class i2c_env extends uvm_env;
    `uvm_component_utils(i2c_env)
    i2c_agent agt; i2c_scoreboard sb; i2c_coverage cov;
    function new(string n, uvm_component p); super.new(n,p); endfunction
    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      agt = i2c_agent::type_id::create("agt", this);
      sb  = i2c_scoreboard::type_id::create("sb", this);
      cov = i2c_coverage::type_id::create("cov", this);
    endfunction
    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      agt.ap.connect(sb.imp);
      agt.ap.connect(cov.analysis_export);
    endfunction
  endclass

  // --- Sequences ---
  class i2c_base_seq extends uvm_sequence #(i2c_item);
    `uvm_object_utils(i2c_base_seq)
    function new(string n="i2c_base_seq"); super.new(n); endfunction
  endclass

  class i2c_directed_seq extends i2c_base_seq;
    `uvm_object_utils(i2c_directed_seq)
    function new(string n="i2c_directed_seq"); super.new(n); endfunction
    task body();
      i2c_item tr;
      tr = i2c_item::type_id::create("wr");
      void'(tr.randomize() with { addr==7'h42; dir==I2C_WRITE; reg_ptr==8'h10; wdata==8'h3C; });
      start_item(tr); finish_item(tr);
    endtask
  endclass

  // class i2c_random_seq extends i2c_base_seq;
  //   `uvm_object_utils(i2c_random_seq)
  //   rand int unsigned n_trans;
  //   constraint c_n { n_trans inside {[50:100]}; }
  //   function new(string n="i2c_random_seq"); super.new(n); endfunction
  //   task body();
  //     i2c_item tr;
  //     for (int i=0; i<n_trans; i++) begin
  //       tr = i2c_item::type_id::create("tr");
  //       void'(tr.randomize() with { addr == 7'h42; });
  //       start_item(tr); finish_item(tr);
  //     end
  //   endtask
  // endclass


    class i2c_random_seq extends i2c_base_seq;
    `uvm_object_utils(i2c_random_seq)
    rand int unsigned n_trans;
    constraint c_n { n_trans inside {[50:150]}; }
    function new(string n="i2c_random_seq"); super.new(n); endfunction

    task body();
      i2c_item tr;
      for (int i=0;i<n_trans;i++) begin
        tr = i2c_item::type_id::create($sformatf("tr_%0d", i));
        void'(tr.randomize() with {
          //addr dist { 7'h42 := 80, [7'h08:7'h77] := 20 };
		addr dist { 7'h42 := 100, [7'h08:7'h77] := 0 };
          reg_ptr dist { [8'h00:8'h0F] := 30, [8'h10:8'hEF] := 60, [8'hF0:8'hFF] := 10 };
          wdata dist { 8'h00 := 10, 8'hFF := 10, [8'h01:8'hFE] := 80 };
        });
        start_item(tr); finish_item(tr);
      end
    endtask
  endclass

  // --- Test ---
  class i2c_test extends uvm_test;
    `uvm_component_utils(i2c_test)
    i2c_env env;
    function new(string n, uvm_component p); super.new(n,p); endfunction
    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      env = i2c_env::type_id::create("env", this);
    endfunction

    function void end_of_elaboration_phase(uvm_phase phase);
      super.end_of_elaboration_phase(phase);
      uvm_test_done.set_drain_time(this, 10us);
    endfunction

    // task run_phase(uvm_phase phase);
    //  // i2c_directed_seq dseq = i2c_directed_seq::type_id::create("dseq");
    //   i2c_random_seq   rseq = i2c_random_seq::type_id::create("rseq");
    //   phase.raise_objection(this);
    // //  dseq.start(env.agt.seqr);
    //   rseq.start(env.agt.seqr);
    //   phase.drop_objection(this);
    // endtask


  task run_phase(uvm_phase phase);
  i2c_random_seq rseq;
  phase.raise_objection(this);
  
  rseq = i2c_random_seq::type_id::create("rseq");
  
  // FORCE n_trans to be 10 to rule out a "0" randomization issue
  if(!rseq.randomize()) //with { n_trans == 51; }) 
    `uvm_error("TEST", "Randomization failed")

    `uvm_info("TEST", "Starting rseq on sequencer", UVM_LOW)
    rseq.start(env.agt.seqr);
    `uvm_info("TEST", "rseq.start has returned - sequence is DONE", UVM_LOW)
  
    phase.drop_objection(this);
    endtask
  endclass

endpackage

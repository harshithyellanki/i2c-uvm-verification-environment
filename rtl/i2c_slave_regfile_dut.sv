`timescale 1ns/1ps
module i2c_slave_regfile_dut #(
  parameter logic [6:0] I2C_SLAVE_ADDR = 7'h42
)(
  input  logic reset_n,
  input  logic scl,
  inout  tri1  sda
);

  // Declare types and state variables
  typedef enum logic [3:0] {
    ST_IDLE, ST_ADDR, ST_ADDR_ACK, ST_REG, ST_REG_ACK,
    ST_WRITE_DATA, ST_WRITE_ACK, ST_READ_DATA, ST_READ_ACK
  } state_t;
  
  state_t state;
  logic sda_drive_low;
  assign sda = (sda_drive_low) ? 1'b0 : 1'bz;

  logic [7:0] regfile [0:255];
  logic [7:0] reg_ptr;
  logic start_seen, stop_seen;
  logic [7:0] shift_in;
  logic [7:0] shift_out;
  logic [2:0] bit_cnt;
  logic addr_match;
  logic rw_bit;

  // --- START Detection ---
  // To avoid multi-driver errors, this is the ONLY block that drives start_seen[cite: 30].
  always_ff @(negedge sda or negedge reset_n) begin
    if (!reset_n)         start_seen <= 1'b0;
    else if (scl == 1'b1) start_seen <= 1'b1;
    else                  start_seen <= 1'b0; // Auto-clear when SCL is low
  end

  // --- STOP Detection ---
  // To avoid multi-driver errors, this is the ONLY block that drives stop_seen[cite: 35].
  always_ff @(posedge sda or negedge reset_n) begin
    if (!reset_n)         stop_seen <= 1'b0;
    else if (scl == 1'b1) stop_seen <= 1'b1;
    else                  stop_seen <= 1'b0; // Auto-clear when SCL is low
  end

  // --- SDA Output Logic (Nedge SCL) ---
  always_ff @(negedge scl or negedge reset_n) begin
    if (!reset_n) begin
      sda_drive_low <= 1'b0;
    end else begin
      sda_drive_low <= 1'b0; 
      unique case (state)
        ST_ADDR_ACK:  if (addr_match) sda_drive_low <= 1'b1;
        ST_REG_ACK,
        ST_WRITE_ACK: if (addr_match) sda_drive_low <= 1'b1;
        ST_READ_DATA: sda_drive_low <= (shift_out[7] == 1'b0);
        default: ;
      endcase
    end
  end

  // --- Main State Machine (Posedge SCL) ---
  always_ff @(posedge scl or negedge reset_n) begin
    if (!reset_n) begin
      state      <= ST_IDLE;
      bit_cnt    <= 3'd0;
      shift_in   <= 8'h00;
      shift_out  <= 8'hFF;
      addr_match <= 1'b0;
      rw_bit     <= 1'b0;
      reg_ptr    <= 8'h00;
      // Note: start_seen/stop_seen are NOT assigned here to avoid vopt-7061
      for (int i=0; i<256; i++) regfile[i] <= 8'h00;
    end else begin
      if (stop_seen) begin
        state      <= ST_IDLE;
        bit_cnt    <= 3'd0;
        addr_match <= 1'b0;
      end else if (start_seen) begin
        // Captures first bit (MSB) immediately while transitioning to avoid missing it
        state       <= ST_ADDR;
        bit_cnt     <= 3'd6; 
        shift_in    <= 8'h00;
        shift_in[7] <= sda;
        addr_match  <= 1'b0;
      end else begin
        unique case (state)
          ST_IDLE: ; 

          ST_ADDR: begin
            shift_in[bit_cnt] <= sda;
            if (bit_cnt == 0) begin
              rw_bit     <= sda;
              // Compare only the 7 address bits [7:1] against parameter
              addr_match <= (shift_in[7:1] == I2C_SLAVE_ADDR); 
              state      <= ST_ADDR_ACK;
            end else begin
              bit_cnt <= bit_cnt - 1;
            end
          end

          ST_ADDR_ACK: begin
            if (addr_match) begin
              if (rw_bit == 1'b0) begin
                state    <= ST_REG; 
                bit_cnt  <= 3'd7;
              end else begin
                shift_out <= regfile[reg_ptr]; 
                state     <= ST_READ_DATA;
                bit_cnt   <= 3'd7;
              end
            end else begin
              state <= ST_IDLE;
            end
          end

          ST_REG: begin
            shift_in[bit_cnt] <= sda;
            if (bit_cnt == 0) begin
              reg_ptr <= {shift_in[7:1], sda};
              state   <= ST_REG_ACK;
            end else begin
              bit_cnt <= bit_cnt - 1;
            end
          end

          ST_REG_ACK: begin
            state    <= ST_WRITE_DATA;
            bit_cnt  <= 3'd7;
          end

          ST_WRITE_DATA: begin
            shift_in[bit_cnt] <= sda;
            if (bit_cnt == 0) begin
              regfile[reg_ptr] <= {shift_in[7:1], sda};
              reg_ptr          <= reg_ptr + 1;
              state            <= ST_WRITE_ACK;
            end else begin
              bit_cnt <= bit_cnt - 1;
            end
          end

          ST_WRITE_ACK: begin
            state    <= ST_WRITE_DATA;
            bit_cnt  <= 3'd7;
          end

          ST_READ_DATA: begin
            if (bit_cnt == 0) begin
              state <= ST_READ_ACK;
            end else begin
              shift_out <= {shift_out[6:0], 1'b1};
              bit_cnt   <= bit_cnt - 1;
            end
          end

          ST_READ_ACK: begin
            if (sda == 1'b0) begin 
              reg_ptr    <= reg_ptr + 1;
              shift_out  <= regfile[reg_ptr + 1];
              state      <= ST_READ_DATA;
              bit_cnt    <= 3'd7;
            end else begin
              state <= ST_IDLE;
            end
          end

          default: state <= ST_IDLE;
        endcase
      end
    end
  end
endmodule
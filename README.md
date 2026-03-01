# I2C Slave UVM Verification Environment

## Overview

This project implements a complete UVM-based verification environment for an I2C slave register-file design. The DUT models a 7-bit I2C slave with an internal 256-byte register file supporting read and write transactions.

The objective of this project is to verify protocol compliance, transaction correctness, and register data integrity using a structured UVM architecture with constrained-random stimulus, monitoring, scoreboard checking, and functional coverage.

This repository demonstrates industry-style verification methodology and layered testbench architecture.


## Design Description

The I2C slave DUT includes:

- 7-bit slave addressing
- Read and write transaction handling
- START and STOP condition detection
- ACK/NACK generation
- Internal 256-byte register file
- Register pointer management

The DUT communicates over SDA and SCL and supports standard I2C transaction flow.


## Verification Architecture

The verification environment follows standard UVM layered architecture and includes:

### 1. Transaction Layer
- I2C sequence item modeling address, direction, register pointer, write data, read data, and ACK behavior.

### 2. Stimulus Generation
- Constrained-random read/write transaction generation.
- Address distribution control.
- Register pointer randomization.

### 3. Driver
- Serializes transactions onto SDA.
- Generates START/STOP conditions.
- Drives data according to I2C timing rules.

### 4. Monitor
- Observes SDA/SCL activity.
- Reconstructs I2C transactions.
- Sends captured transactions to scoreboard.

### 5. Scoreboard
- Maintains a reference register model.
- Compares expected vs actual read data.
- Flags mismatches.

### 6. Functional Coverage

Covers:
- Address space utilization
- Read vs Write distribution
- Register pointer values
- Data patterns
- ACK behavior


## Project Structure

i2c_uvm_regfile_variant/
│
├── rtl/                # I2C slave register-file DUT  
├── tb/                 # UVM testbench components  
├── scripts/            # Questa .do scripts  
├── modelsim.ini        # ModelSim configuration  
├── work/               # Simulation library (generated)  
├── transcript          # Simulation transcript (generated)  
└── README.md  


## Simulation Instructions

This project is developed for use with QuestaSim / ModelSim.

All commands are run from the project root directory.


### Compile and Run (Batch Mode)

vsim -c -do "do questa_compile_regfile.do; vsim work.top_tb_regfile -do 'run -all; quit'; quit"

This command:
- Compiles RTL and testbench
- Launches testbench top
- Runs simulation
- Exits automatically


### Run Only (After Compilation)

vsim -c work.top_tb_regfile -do "run -all; quit"


### GUI Mode with Waveforms

vsim work.top_tb_regfile -do questa_run_regfile_gui.do

This launches the GUI and loads waveform configuration.


## Verification Flow

1. Generate constrained-random write transaction.
2. Drive register pointer and data via I2C.
3. Issue read transaction.
4. Monitor reconstructs bus activity.
5. Scoreboard validates data correctness.
6. Functional coverage updated.


## Key Verification Features

- Constrained-random stimulus
- Self-checking scoreboard
- Protocol-aware monitoring
- Functional coverage collection
- Script-based simulation automation


## Future Enhancements

- Integration of UVM Register Abstraction Layer (RAL)
- SystemVerilog Assertions for protocol timing checks
- Error injection tests
- Regression automation
- Coverage report integration


## Author

Rohit Yellanki  
SystemVerilog | UVM | Digital Design Verification

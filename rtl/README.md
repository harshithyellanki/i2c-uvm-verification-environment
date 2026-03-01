I2C UVM Verification Environment
Overview

This project implements a complete UVM-based verification environment for an I2C slave register-file DUT. The environment verifies protocol correctness, register transactions, and data integrity using constrained-random stimulus, functional coverage, and a scoreboard-based checking mechanism.

The DUT models an I2C slave with an internal 256-byte register file supporting read and write operations via standard I2C transactions.

This repository demonstrates a structured, reusable, and scalable UVM verification architecture aligned with industry-style design verification workflows.

Project Structure
i2c_uvm_regfile_variant/
│
├── rtl/                # I2C slave register-file DUT
├── tb/                 # UVM testbench components
├── scripts/            # Questa simulation scripts (.do files)
├── modelsim.ini        # ModelSim configuration
├── work/               # Simulation library (placeholder)
├── transcript          # Simulation transcript (generated)
└── .gitignore
Design Under Test (DUT)

7-bit I2C slave address

256-byte internal register file

START/STOP detection

Read/Write transaction handling

ACK/NACK response logic

Register pointer management

Verification Architecture

The verification environment follows standard UVM layered architecture.

Sequence Item

Models I2C transactions including:

Address

Direction (Read/Write)

Register pointer

Write data

Read data

ACK behavior

Sequences

Constrained-random read/write generation

Address and data randomization

Register pointer variation

Driver

Drives SDA and SCL signals

Generates START and STOP conditions

Serializes transaction data onto the I2C bus

Monitor

Observes SDA/SCL

Reconstructs bus transactions

Sends transactions to scoreboard via analysis ports

Scoreboard

Maintains a reference register model

Compares expected vs actual read data

Flags mismatches

Functional Coverage

Covers:

Address space

Read/Write distribution

Register pointer coverage

Data pattern coverage

ACK/NACK behavior

I2C Protocol Features Verified

START condition detection

STOP condition detection

7-bit addressing

Read/Write bit handling

Register pointer updates

Multi-byte transactions

ACK/NACK validation

Simulation

This project is intended for QuestaSim / ModelSim.

All commands are run from the project root directory.

1. Compile + Run (Batch Mode)
vsim -c -do "do questa_compile_regfile.do; vsim work.top_tb_regfile -do 'run -all; quit'; quit"

This command:

Executes compilation script (questa_compile_regfile.do)

Launches testbench (top_tb_regfile)

Runs full simulation

Exits automatically

2. Run Only (After Compilation)
vsim -c work.top_tb_regfile -do "run -all; quit"

Used when the design is already compiled.

3. GUI Mode with Waveforms
vsim work.top_tb_regfile -do questa_run_regfile_gui.do

This:

Launches GUI

Loads waveform configuration

Runs simulation interactively

Example Verification Flow

Generate constrained-random write transaction

Drive I2C bus with register pointer and data

Issue read transaction

Monitor reconstructs bus activity

Scoreboard validates read data

Functional coverage updated

Why This Project Is Valuable

This project demonstrates:

Strong understanding of UVM methodology

Protocol-level verification skills

Self-checking verification environment design

Constrained-random verification

Functional coverage integration

Script-based simulation automation

The architecture reflects practical industry-level digital verification practices.

Future Enhancements

Integrate UVM Register Abstraction Layer (RAL)

Add SystemVerilog Assertions (SVA) for protocol timing

Add error injection tests

Add regression automation script

Include coverage report snapshots

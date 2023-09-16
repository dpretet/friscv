# Verification Testsuites

The next folders contain all the verification testsuites within the hart is tested.

All the testcases rely on [SVUT](https://github.com/dpretet/svut) and
[Icarus Verilog](http://iverilog.icarus.com) or [Verilator](https://github.com/verilator).

The testbench provides two configurations:

- `core`: the hart is connected upon an AXI4-lite dual port RAM model, the instruction
  bus on one port, the data bus on the other. Hart-only configuration.
- `platform`: the core is connected upon an AXI4 crossbar with some peripherals
  (GPIOs, UART, CLINT) and share the same master interface to the AXI4-lite RAM model.

All testsuites support different tools and configurations, except [Apps](./apps) which support only
Verilator and `platform` top level. A testsuite can contain one or more ASM/C files.

To execute the flow, possible arguments are:

```bash
# To run all testcases over a specific configuration
./run.sh --tb "core"     // to run the core-only simulation
./run.sh --tb "platform" // to run the platform, the core + the peripherals

# To run with a specific simulator:
./run.sh --simulator verilator

# To run a specific testcase:
./run.sh --tc ./tests/rv32ui-p-test0.v

# Combined arguments:
./run.sh --tb platform --simulator --tc ./tests/rv32ui-p-test0.v
```

[Common](../common) folder contains:

- `sim_main.cpp`: the verilator C++ testbench
- `bin2hex.py`: the utility to convert the assembler to binary used to initialize the RAM booted by
  the core
- `functions.sh`: a setup of functions used compile and run the testsuites
- `trace.py`: a script to format the trace of the hart logging the jump/branch (debug purpose)
- `axi4l_ram.sv`: the RAM used to store the program and boot the core
- a set of waveform, ready to use:
    - `debug_core_icarus.gtkw`
    - `debug_core_verilator.gtkw`
    - `debug_platform_icarus.gtkw`
    - `debug_platform_verilator.gtkw`
- `files.f`: the file list to compile the testbench
- `friscv_testbench.sv`: the system verilog testbench
- `lfsr.sv`: a pseudo-random number generator used across the testbench

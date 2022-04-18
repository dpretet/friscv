# Apps Tetsuite

This testsuite is composed by several small and basic applications

The testbench provides two configurations:

- core: the hart is connected upon an AXI4-lite dual port RAM model, the instruction
  bus on one port, the data bus on the other
- platform: the core is connected upon an AXI4 crossbar with some peripherals
  (GPIOs, UART, CLINT) and share the same master interface to the AXI4-lite RAM molde

To execute the flow:

```bash
./run.sh --tb "CORE" // to run the core only simulation
./run.sh --tb "PLATFORM" // to run the platform, the core + the peripherals
```

This will make all programs in tests\* folders, copy the RAM content generated,
convert it to Verilog format then execute SVUT to run the testbench on each
testcase.

For more information about the bash front-end flow:

```bash
./run.sh -h
```

All the testcases rely on [SVUT](https://github.com/dpretet/svut) and use
[Icarus Verilog](http://iverilog.icarus.com) or [Verilator](https://github.com/verilator).

[Common](tests/common) folder contains a Makefile and a linker setup shared between
all the testcases and symlinked into each test folder. A C runtime (crt0.S) is also provided
to applications to boot the processor, initialize the stack and jump to the main.

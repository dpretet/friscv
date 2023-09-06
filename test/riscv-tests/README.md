# RISCV-Tests

Official compliance testsuite from [RISCV test github](https://github.com/riscv/riscv-tests/).

To execute the flow:

```bash
./run.sh --simulator icarus
./run.sh --simulator verilator
./run.sh --tb platform
./run.sh --tb core
```

This will make all programs in tests/* folders, copy the RAM content generated,
convert it to Verilog format then execute SVUT to run the testbench on each
testcase.

All the testcases rely on [SVUT](https://github.com/dpretet/svut) and
[Icarus Verilog](http://iverilog.icarus.com) or [Verilator](https://github.com/verilator).

[Common](../common) folder contains a Makefile and a linker setup shared between
all the testcases and symlinked into each test folder. A folder can contain
one or more ASM/C file and a markdown file describing the testcase scenarios.

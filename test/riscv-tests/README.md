# RISCV-Tests

Official compliance testsuite from [RISCV](https://github.com/riscv/riscv-tests/)

To execute the flow:

```bash
./run.sh
```

All the testcases rely on [SVUT](https://github.com/dpretet/svut) to and
[Icarus Verilog 11](http://iverilog.icarus.com).

[Common](../common) folder contains a Makefile and a linker setup shared between
all the testcases and symlinked into each test folder. A folder can contain
one or more ASM/C file and a markdown file describing the testcase scenarios.

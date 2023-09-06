# Apps Testsuite

## Overview

This testsuite is composed by several applications, stressing out C toolchain and
benchmarking the core.

The testbench provides only "platform" support (CPU + AXI4 interconnect). The applications
are interactive and require user inputs.

To execute the flow:

```bash
./run.sh --tc tests/repl.v
```

All the testcases rely on [SVUT](https://github.com/dpretet/svut) and
[Icarus Verilog](http://iverilog.icarus.com) or [Verilator](https://github.com/verilator).

[Common](tests/common) folder contains a Makefile and a linker setup shared between
all the testcases and symlinked into each test folder. A C runtime (crt0.S) is also provided
to boot the processor, initialize the stack and jump to the main.

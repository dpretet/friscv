# Apps Testsuite

## Overview

This testsuite is composed by several applications, stressing out C toolchain and
verifying the core with different applications.

The testbench provides only `platform` support (CPU + AXI4 interconnect) and `verilator`. 
The applications are interactive and require user inputs.

To execute the flow:

```bash
./run.sh --tc tests/repl.v
```

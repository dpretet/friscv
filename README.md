# FRISCV


## Overview

FRISCV is a SystemVerilog implementation of  [RISCV ISA](https://riscv.org).

Currently it supports:

- RV32i instruction set, further more will be implemented soon
- 2 stage pipeline
- in-order execution
- GPIO + UART

To be implemented next:

- interrupt
- timer
- privileged instruction
- AXI4-lite support for data memory interface to support outstanding request,
  ID, protection, error management
- cache stages for instruction and data memory
- branch prediction for instruction cache
- ... and many more :)

The core is verified with SystemVerilog and Assembler, two testsuites are
present in [test](./test) folder:
- [Assembler testsuite](./test/asm_testsuite/README.md)
- [SystemVerilog testsuite](./test/rtl_unit_tests/README.md)


This is work in progress... but an active work !


## License

This IP core is licensed under MIT license. It grants nearly all rights to use,
modify and distribute these sources. However, consider to contribute and provide
updates to this core if you add feature and fix, would be greatly appreciated :)

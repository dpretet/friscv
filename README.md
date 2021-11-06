# FRISCV


## Overview

FRISCV is a SystemVerilog implementation of  [RISCV ISA](https://riscv.org):

- Support RV32I & RV32E instruction sets
- 3-stage pipeline
- In-order execution
- Instruction cache
- AXI4-lite interface for instruction and data bus
- Machine-mode only
- Interrupt (CLINT)
- Timer
- [RISCV compliant](./test/riscv-tests/README.md)

<p align="center">
  <!--img width="100" height="100" src=""-->
  <img src="doc/assets/friscv-top.png">
</p>


To be implemented next:

- Supervisor & user mode
- New ISA extensions (mult/div, FP, ...)
- Data cache stage
- 64 bits architecture
- JTAG interface for debugging purpose
- ... and many more :)

The core is verified with Assembler, two testsuites are present in
[test](./test) folder:
- [In-house Assembler Testsuite](./test/asm_testsuite/README.md)
- [RISCV Compliance Testsuite](./test/riscv-tests/README.md)


This is work in progress... but an active work !


## License

This IP core is licensed under MIT license. It grants nearly all rights to use,
modify and distribute these sources.

However, consider to contribute and provide updates to this core if you add
feature and fix, would be greatly appreciated :)

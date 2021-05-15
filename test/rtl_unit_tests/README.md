# RTL Unit Tests

Here the user can find the directed testcases written to
test:
- [Control Unit](./friscv_rv32i_control_unit_testbench.sv)
- [ALU](./friscv_rv32i_alu_testbench.sv)
- [Memory controller](./friscv_rv32i_memfy_testbench.sv)
- [Instruction decoder](./friscv_rv32i_decoder_testbench.sv)

The testsuites are directed, written in pure SystemVerilog to drive and check
the expected behaviors of these cores.

All the testsuites rely on [SVUT](https://github.com/dpretet/svut) to and
[Icarus Verilog](http://iverilog.icarus.com).

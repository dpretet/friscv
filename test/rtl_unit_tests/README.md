# RTL Unit Tests

Here the user can find the directed testcases written to
test:
- [Control Unit](./friscv_rv32i_control_unit_testbench.sv)
- [ALU](./friscv_rv32i_alu_testbench.sv)
- [FRISCV RV32i](./friscv_rv32i_testbench.sv)

Control unit and ALU testsuites are directed, written in
pure SystemVerilog to drive and check the expected behaviors
of these cores.

FRISCV RV32i testsuites is an emulation of the integration
of the processor core in a complete. It connects the IOs
interfaces (instruction & data bus) on SCRAM models,
configurable in term of latency. It relies on test vectors
loaded by the testcases on-the-fly to initialize the RAMs.

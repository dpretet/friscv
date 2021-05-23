# ASM Unit Tests - Interasactive mode

FRISCV RV32i testsuite is an emulation of the integration of the processor core
in a complete env. It connects the IOs interfaces (instruction & data bus) on
SCRAM models. The test vectors are created from ASM programs, built and then
converted into files to initialize the RAMs.

The intent of this flow is to create programs to stress the IP's core
integration and check the behavior's correctness based on real program.

To execute the flow:

```bash
./run.sh
```

This will make all programs in test\* folders, copy the RAM content generated,
convert it to Verilog format then execute SVUT to run the testbench on each
testcase.

All the testcases rely on [SVUT](https://github.com/dpretet/svut) to and
[Icarus Verilog](http://iverilog.icarus.com).

[common](./common) folder contains a Makefile and a linker setup shared between
all the testcases and symlinked into each test folder. A folder can contain
one or more ASM/C file and a markdown file describing the testcase scenario.


Resources:

https://github.com/rdiez/uart_dpi
https://www.linuxhowtos.org/C_C++/socket.htm
https://jameshfisher.com/2017/04/05/set_socket_nonblocking/
https://stackoverflow.com/questions/13833880/how-can-i-convince-iverilog-that-the-vpi-is-a-system-function-and-not-a-task

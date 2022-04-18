# White-Box Assembler Testsuite

WBA testsuite is an example of integration of the processor core in a complete environment.

The testbench provides two configurations:

- core: the hart is connected upon an AXI4-lite dual port RAM model, the instruction
  bus on one port, the data bus on the other
- platform: the core is connected upon an AXI4 crossbar with some peripherals
  (GPIOs, UART, CLINT) and share the same master interface to the AXI4-lite RAM molde

For both setup, the test vectors are created from ASM programs, built and then
converted into files to initialize the RAMs.

The intent of this flow is to create programs to stress the IP's core
with a white-box strategy.

To execute the flow:

```bash
./run.sh --tb "CORE" // to run the core only simulation
./run.sh --tb "PLATFORM" // to run the platform, the core + the peripherals
```

This will make all programs in tests\* folders, copy the RAM content generated,
convert it to Verilog format then execute SVUT to run the testbench on each
testcase.

All the testcases rely on [SVUT](https://github.com/dpretet/svut) and use
[Icarus Verilog](http://iverilog.icarus.com) or [Verilator](https://github.com/verilator).

For more information about the bash front-end flow:

```bash
./run.sh -h
```

[Common](../common) folder contains a Makefile and a linker setup shared between
all the testcases and symlinked into each test folder. A folder can contain
one or more ASM/C file.

The compilation flow is derivated from RISCV official compliance testsuite,
relying on its C flow to do unit testing.

# Test plan

## Test 1: Sequence of LUI/AUIPC/Arithmetic instructions

Injects a set of alternating LUI / AUIPC / aritmetic instructions to ensure the
control unit correctly handles this kind of situation. All these instructions
are executed in one cycle and shouldn't introduce any wait cycles between each
others.

## Test2: Sequence of LOAD/STORE/ARITHMETIC instructions

Injects a set of alternating LUI / AUIPC / LOAD  /STORE aritmetic instructions
to ensure the control unit correctly handles this kind of situation.

While aritmetic instructions are completed in one cycle, LOAD and STORE can
span over several cycles. This test will ensure incoming instructions between
them will not be lost and so the control unit properly manages this situation.

## Test 3: Check FENCE/FENCE.i instructions

Place FENCE and FENCE.i between ALU and memfy instructions. The test is
supposed for the moment harmless because the processor doesn't support neither
out-of-order or parallel executions.

## Test 4: JAL/JALR: Throttle execution by jumping back and forth

This testcase executes memory and arithmetic instructions break up by JAL and
JALR instruction to ensure branching doesn't introduce failures.

## Test 5: CSRs: Throttle execution by acessing the ISA CSRs

This testcase executes memory and arithmetic instructions break up by CSR
accesses. CSR instructions require several cycles to complete, thus could lead
to failure in control unit.

## Test 6: WFI - Asynchronous Interrupts

This testcase tries to catch up interrupts, external, software and timer interrupts.

To be written.

## Test 7: Traps - Synchronous Interrupts

This testcase tries to catch up synchronous interrupts

To be written.


# White-Box Assembler Testsuite

WBA testsuite is an example of integration of the processor core in a complete environment. The
intent of this flow is to create programs to stress the IP's core with a white-box strategy, very
driven by the architecture.

For more information about the bash front-end flow:

```bash
./run.sh -h
```

## Test 1: LUI/AUIPC/Arithmetic interleaving

Injects a set of alternating LUI / AUIPC / aritmetic instructions to ensure the
control unit correctly handles this kind of situation. All these instructions
are executed in one cycle and shouldn't introduce any wait cycles between each
others.

## Test 2: LOAD/STORE/ARITHMETIC interleaving

Injects a set of alternating LUI / AUIPC / LOAD  /STORE aritmetic instructions
to ensure the control unit correctly handles this kind of situation.

While aritmetic instructions are completed in one cycle, LOAD and STORE can
span over several cycles. This test will ensure incoming instructions between
them will not be lost and so the control unit properly manages this situation.

## Test 3: FENCE/FENCE.i instructions

Executes FENCE and FENCE.i between ALU and memfy instructions. The test is
supposed for the moment harmless for FENCE because the processor doesn't support neither
out-of-order or parallel executions.

## Test 4: JAL/JALR - Throttle execution by jumping back and forth

Executes memory and arithmetic instructions break up by JAL and
JALR instruction to ensure branching doesn't introduce failures.

## Test 5: CSRs access

Executes memory and arithmetic instructions break up by CSR accesses.

## Test 6: LOAD/STORE outstanding requests

Stresses out outstanding requests management in Memfy module when issuing
multiple read or write requests.

## Test 7: RDCYCLE/RDTIME/RDINSTRET

Checks instret, cycle and time are incremented accordingly the spec

## Test 8: WFI

Setup interrupt and checks the core manages EIRQ correctly.

## Test 9: M extension

Check multiply /division extension

## Test 10: LOAD/STORE collision

Stresses out read / write with memfy and check collisions don't occur

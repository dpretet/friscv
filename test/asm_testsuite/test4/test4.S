# x1 register used along the testcase
addi x1, x1, 1

# Gegisters used to compare the results
addi x11, x11, 3
addi x12, x12, 3
addi x13, x13, 4
lui x14, 1
# Register used to store origin
add  x20, x20, 0
# Register used to store nb of errors
addi x31, x31, 0

jal x20, BACKnFORTH
jal x20, BACKnFORTH
jal x20, BACKnFORTH

addi x1, x1, 1
sw x1, 0(x0)
jal x20, BACKnFORTH
lw x1, 0(x0)
addi x1, x1, 1

auipc x10, 0
addi x10, x10, 12
bne x11, x1, FAIL

sw x1, 0(x0)
addi x1, x1, 1
jal x20, BACKnFORTH
lw x1, 0(x0)

auipc x10, 0
addi x10, x10, 12
bne x12, x1, FAIL

lw x1, 0(x0)
jal x20, BACKnFORTH
addi x1, x1, 1
sw x1, 0(x0)

auipc x10, 0
addi x10, x10, 12
bne x13, x1, FAIL

lw x1, 0(x0)
jal x20, BACKnFORTH
addi x1, x1, 1
sw x1, 0(x0)
lui x1, 1

auipc x10, 0
addi x10, x10, 12
bne x14, x1, FAIL

nop
nop
nop
ebreak

BACKnFORTH:
    jalr x0, 0(x20)

FAIL:
    add x31, x31, 1
    jalr x0, x10, 0

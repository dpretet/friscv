lui  x1, 0
lui  x2, 0
lui  x3, 0

addi x11, x11, 1
addi x12, x12, 0x2e
lui x13, 1
addi x31, x31, 0

auipc x1, 0
lui  x1,0
addi x1, x1, 1 

lui  x2, 0
auipc x2, 0
addi x2, x2, 2 

addi x3, x3, 2
auipc x3, 2
lui x3, 1

auipc x10, 0
addi x10, x10, 12
bne x11, x1, FAIL

auipc x10, 0
addi x10, x10, 12
bne x12, x2, FAIL

auipc x10, 0
addi x10, x10, 12
bne x13, x3, FAIL

ebreak

FAIL:
    add x31, x31, 1
    jalr x0, x10, 0

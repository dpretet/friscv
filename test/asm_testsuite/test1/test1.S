lui  x1,1
lui  x2,0
lui  x3,0
lui  x4,0
lui  x5, 4
lui  x31,0
addi x2, x0, 1
bne x1, x2, ERROR

sb x5, 0(x0)
lb x6, 0(x0)
sw x5, 0(x5)
lw x7, 0(x5)

ERROR:
    addi x31, x31, 1
    jal x0, ERROR

# x1 register used along the testcase
addi x1, x1, 0x1
addi x2, x2, 0x8
addi x3, x3, 0x14

# Configure the UART
sw x1, 0(x2)
# Read the RX FIFO
lw x1, 0(x3)
nop
nop

ebreak

BACKnFORTH:
    jalr x0, 0(x20)

FAIL:
    add x31, x31, 1
    jalr x0, x10, 0

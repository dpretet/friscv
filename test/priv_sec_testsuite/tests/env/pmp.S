# distributed under the mit license
# https://opensource.org/licenses/mit-license.php

.equ PMPADDR,   0xFFFFFFFF
.equ PMPCFG,    0x77777777

.equ S2MB,      0x200000
.equ S1MB,      0x100000
.equ S512K,     0x80000
.equ S256K,     0x40000
.equ S64KB,     0x10000
.equ S16KB,     0x10000
.equ S4KB,      0x4000
.equ S1KB,      0x1000

.equ OFF,       0
.equ TOR_RWX,   0x0F
.equ TOR_RW,    0x0B
.equ TOR_RX,    0x0D
.equ NA4_RWX,   0x17
.equ NA4_RW,    0x13
.equ NA4_RX,    0x15
.equ NAPOT_RWX, 0x1F
.equ NAPOT_RW,  0x1B
.equ NAPOT_LRW, 0x9B
.equ NAPOT_RX,  0x1D
.equ NAPOT_R,   0x19
.equ NAPOT_W,   0x1C

.equ TOR_LRWX,   0x8F
.equ TOR_LRW,    0x8B
.equ TOR_LRX,    0x8D
.equ NA4_LRWX,   0x97
.equ NA4_LRW,    0x93
.equ NA4_LRX,    0x95
.equ NAPOT_LRWX, 0x9F
.equ NAPOT_LRW , 0x9B
.equ NAPOT_LRX , 0x9D

.equ TOR,       0x08
.equ NA4,       0x10
.equ NAPOT,     0x18

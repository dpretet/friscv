# User Mode Design

- [X] Support U-mode:
    - Previous privilege mode interrupt is stored in xPP to support nested trap
    - Ecall move to M-mode
    - Mret move to U-mode
- [X] Support exceptions
    - M-mode instructions executed in U-mode must raise an illegal instruction exception
    - Access to M-mode only registers must raise an illegal instruction exception
    - ecall code when coming from U-mode in mcause
- [X] Support PMP (Physical Memory Protection)
    - Instruction read or data R/W access are checked against PMP to secure the hart
    - Address is checked with CSRs pmpcfg
    - Up to 16 zones can be defined
    - A zone can be readable, writable, executable
    - PMP checks are applied to all accesses whose effective privilege mode is S or U, including
      instruction fetches and data accesses in S and U mode, and data accesses in M-mode when the
      MPRV bit in mstatus is set and the MPP field in mstatus contains S or U (page 56 & page 23)
- [X] Study PMA (Physical Memory Attribute) (section 3.6)
    - define R/W/X et l'address matching
    - le PMA ne permet pas de définir des zones d'IO et/ou si une region peut etre cohérente
- [X] WFI:
    - [X] if MIE/SIE=1, wait for one of them and trap to m-mode. Resume to mepc=pc+4
    - [X] if MIE/SIE=0, wait for any intp and move forward
    - [X] Support MSTATUS.TW (timeout platform-dependent)
- [X] add FIFO for memory exceptions
- [X] Drive aprot[0] based on priviledge mode
- [X] mcounteren: accessibility to lower privilege modes
    - Bit x = 1, lower privilege mode can read the counter
    - Bit x = 0, lower privilege mode access is forbidden and raise an illegal instruction exception

# Testcases

- [X] Faire varier la periode de l'EIRQ

U-mode
- [X] pass from/to m-mode/u-mode
- [X] try mret in u-mode, needs to fail
- [X] try to access m-mode only CSRs

Traps
- [X] Do something within a loop with interrupt enabled, data needs to be OK
- [X] WFI in u-mode, interrupt enabled, trapped in m-mode
- [X] WFI in u-mode, interrupt disabled, NOP
- [X] Test des exception load/store misaligned
- [ ] Add test for vector table
- [ ] Test MSTATUS.TW

MPU:
- [X] configure registers
- [X] all region configuration mode: NA4 / NAPOT / TOR
- [X] multiple mixed region type and size
- [-] Access exceptions
    - [X] execute instruction outside allowed regions (U-mode)
    - [X] write data in U-mode
    - [X] read data in U-mode
    - [X] read data in M-mode with MPRV=1 + MPP=U-mode
    - [X] write data in M-mode with MPRV=1 + MPP=U-mode
    - [X] execute in M-mode without X + locked region
- [X] locked access to change configuration

MCOUNTER:
- Bit x = 1, lower privilege mode can read the counter
- Bit x = 0, lower privilege mode access is forbidden and raise an illegal instruction exception

Final:
- Pass compliance with U-mode
- Run REPL app
- Review testcases
- Parse again the documentation

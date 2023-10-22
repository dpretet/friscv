# User Mode

- write tests for interrupts
    - enhance existing, existing tests are very poor
    - add test for vector table
    - Test des exception load/store misaligned
- add FIFO for memory exceptions
    - avoid to loose a trap if highest interrupt trap occurs

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
- [ ] Study PMA (Physical Memory Attribute) (section 3.6)
    - define R/W/X et l'address matching
    - le PMA ne permet pas de définir des zones d'IO et/ou si une region peut etre cohérente
- [ ] Support cycle registers per mode
- [ ] WFI:
    - [ ] if MIE/SIE=1, wait for one of them and trap to m-mode. Resume to mepc=pc+4
    - [ ] if MIE/SIE=0, wait for any intp and move forward
    - [ ] Support MSTATUS.TW (timeout platform-dependant)
- [ ] mcounteren: accessibility to lower privilege modes
- [ ] mcountinhibit: stop a specific counter
- [ ] Machine Environment Configuration Registers (menvcfg and menvcfgh)

TESTS

U-mode
- pass from/to m-mode/u-mode
- try mret in u-mode, needs to fail
- try to access m-mode only CSRs

Interrupt
- do something wothin a loop with interrupt enabled, data needs to be OK
- WFI in u-mode, interrupt enabled, trapped in m-mode
- WFI in u-mode, interrupt disabled, NOP

MPU:
- [X] configure registers
- [ ] all region configuration mode: NA4 / NAPOT / TOR
- [ ] multiple mixed region type and size
- [ ] Access exceptions
    -> Store = store access-fault
    -> Load = load access-fault
    -> Execute = instruction access-fault
    - [ ] read/execute instruction outside allowed regions (U-mode)
    - [ ] read/write data in U-mode
    - [ ] read/write data in M-mode with MPRV + MPP w/ U-mode
- [ ] locked access to change configuration
- [ ] locked region accessed wrongly by m-mode- pass xIE & xIP to the control
- [ ] test MSTATUS.TW

- Pass compliance with U-mode
- Re-parse the documentation
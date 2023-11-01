# Privilege / Security Testsuite

Testsuite very dedicated to privilege and security features in the HART.

For more information about the bash front-end flow:

```bash
./run.sh -h
```

## Test 0: M-mode/U-mode transition

Basic test to ensure we can move back and forth the modes and manage correctly ecall/mret and
execute a basic program. It also checks the error management if u-mode runtime tries to use m-mode
instructions or tries to access CSR registers reserved to m-mode

## Test 1: Interrupts

Generate interrupts and manage them. Check U-mode move back M-mode to handle the interrupt. Check
WFI is correctly supported by U-mode.

## Test 2: Check PMP Regions

Checks the three memory region types and tries access across the region and out of its boundaries

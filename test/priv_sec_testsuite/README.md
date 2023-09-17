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

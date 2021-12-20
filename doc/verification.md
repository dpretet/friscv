# Verification Plan


Interrupt management

An interrupt is arriving while the MIP register is under write. Should it be written
by the CSR access or driven by the incoming interrupt

Cache issue:

Un set d’instruction est demandé:
- La 1ere est cache miss
- La 2eme est cache hit
- Les suivantes hit ou miss

Est ce que des instructions peuvent revenir out-of-order dans la control unit


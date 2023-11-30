# Coremark

Coremark benchmark from [Github](https://github.com/eembc/coremark)

To build the elf and binary file

```
make all
```

Printf is functional but time computed is wrong because the division result inferior to 0.

Score: 444 coremark/MHz measured with 10 iterations in 0.45 ms @ 500 MHz

To compute it:

```
nb iteration / time measured * 1000 = score
score / frequency in MHz = coremark / MHz
```

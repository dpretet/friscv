# Coremark

Coremark benchmark from [Github](https://github.com/eembc/coremark)

To build the elf and binary file

```
make all
```

To compute the score:

```
coremark score = nb iteration / time (in seconds)
coremark per MHz = score / frequency (in MHz)
```

Core works @ 500 MHz

With compilation -o0 : 45 ms for 10 iteration = 0.44 coremark / MHzs
With compilation -o1 : 7 ms for 10 iterations = 2.85 coremark / MHz
With compilation -o2 : 10.8 ms for 10 iteration = 1.8 coremark / MHzs
With compilation -o3 : 10.8 ms for 10 iteration = 1.8 coremark / MHzs

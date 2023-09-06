# SystemVerilog Testsuite

Testbenches to verify modules with system verilog unit testing

Two are available:
- icache, dedicated to instruction cache
- dcache, dedicated to data cache

Both uses `driver.sv` to inject alternate read / write requests, checking data
consistency and timeout.

```bash
./run.sh --tb icache_testbench.sv -m 100 --timeout 10000
./run.sh --tb dcache_testbench.sv -m 100 --timeout 10000
```

Driver uses `ram_128b.txt` as source of data to initialize its internal RAM.

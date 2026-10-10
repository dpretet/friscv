---
name: FRISCV RTL Synthesis
description: Run and interpret FRISCV Yosys synthesis flows without overstating implementation, area, timing, or signoff results
---

## Repository flow

The documented top-level synthesis command is `./flow.sh syn`. It runs both
`syn/yosys/syn_asic.sh` and `syn/yosys/syn_x7.sh` for the `friscv_rv32i_core`
top. The ASIC Yosys script uses `syn/yosys/friscv_rv32i.ys` and `cmos.lib`; the
XC7 script uses Yosys `synth_xilinx` for `xc7`.

Before running:

1. Inspect `git status` and check whether synthesis logs or outputs already have
   user changes.
2. Confirm Yosys is available. Do not install tools or trigger network access
   without approval.
3. Check the scripts for their current source list, parameters, and output paths;
   report if the changed RTL is omitted from a synthesis source list.
4. Run synthesis only when requested or appropriate to the task. `./flow.sh syn`
   updates root `syn_asic.log` and `syn_x7.log`; Yosys scripts also write output
   under `syn/yosys/`, including generated netlists/logs.

## Interpretation

- Report exact commands, tool versions, warnings/errors, target top, and
  configuration that the scripts actually synthesize.
- Distinguish successful synthesis from timing closure, physical implementation,
  formal equivalence, FPGA validation, or hardware testing. The repository flow
  alone does not establish those signoff results.
- Do not compare area figures across targets/tools/configurations as though they
  were equivalent. Do not claim a PPA improvement unless the relevant baseline
  and comparable measurements are available.
- Do not edit generated netlists or logs to make a run appear successful.

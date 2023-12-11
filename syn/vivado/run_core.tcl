#/usr/bin/env bash

export PART="xc7k160tffv676-1"
export TOP="friscv_rv32i_core"

vivado -mode tcl -source vivado.tcl | tee $TOP.log

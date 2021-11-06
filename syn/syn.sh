#!/usr/bin/env bash

# -e: exit if one command fails
# -o pipefail: causes a pipeline to fail if any command fails
set -e -o pipefail

SRCS="\
../rtl/friscv_csr.sv \
../rtl/friscv_registers.sv \
../rtl/friscv_rv32i_alu.sv \
../rtl/friscv_rv32i_control.sv \
../rtl/friscv_rv32i_decoder.sv \
../rtl/friscv_rv32i_memfy.sv \
../rtl/friscv_rv32i_processing.sv \
../rtl/friscv_scfifo.sv \
../rtl/friscv_scfifo_ram.sv \
../rtl/friscv_icache.sv \
../rtl/friscv_icache_fetcher.sv \
../rtl/friscv_icache_lines.sv \
../rtl/friscv_rv32i_core.sv "

yosys -DARTY \
      -p "scratchpad -set xilinx_dsp.multonly 1" \
      -p "read -sv -I../dep/svlogger -I../rtl $SRCS" \
      -p "synth_xilinx -nowidelut -flatten -abc9 -arch xc7 -top friscv_rv32i_core " \
      | tee syn.log

exit

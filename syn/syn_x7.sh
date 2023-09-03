#!/usr/bin/env bash

# -e: exit if one command fails
# -o pipefail: causes a pipeline to fail if any command fails
set -e -o pipefail

SRCS="\
../rtl/friscv_alu.sv \
../rtl/friscv_apb_interconnect.sv \
../rtl/friscv_bit_sync.sv \
../rtl/friscv_checkers.sv \
../rtl/friscv_clint.sv \
../rtl/friscv_control.sv \
../rtl/friscv_csr.sv \
../rtl/friscv_dcache.sv \
../rtl/friscv_decoder.sv \
../rtl/friscv_div.sv \
../rtl/friscv_gpios.sv \
../rtl/friscv_h.sv \
../rtl/friscv_icache.sv \
../rtl/friscv_icache_blocks.sv \
../rtl/friscv_icache_fetcher.sv \
../rtl/friscv_icache_memctrl.sv \
../rtl/friscv_io_subsystem.sv \
../rtl/friscv_m_ext.sv \
../rtl/friscv_mem_router.sv \
../rtl/friscv_memfy.sv \
../rtl/friscv_pipeline.sv \
../rtl/friscv_processing.sv \
../rtl/friscv_registers.sv \
../rtl/friscv_rv32i_core.sv \
../rtl/friscv_rv32i_platform.sv \
../rtl/friscv_scfifo.sv \
../rtl/friscv_scfifo_ram.sv \
../rtl/friscv_stats.sv \
../rtl/friscv_lut.sv \
../rtl/friscv_uart.sv"

yosys -g -DARTY \
      -p "scratchpad -set xilinx_dsp.multonly 1" \
      -p "verilog_defaults -add -I../rtl" \
      -p "read -define XLEN=32 -sv -I../rtl $SRCS " \
      -p "synth_xilinx -nowidelut -flatten -abc9 -arch xc7 -top friscv_rv32i_core " \
      $SRCS | tee syn.log

exit

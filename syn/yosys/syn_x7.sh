#!/usr/bin/env bash

# -e: exit if one command fails
# -o pipefail: causes a pipeline to fail if any command fails
set -e -o pipefail

SRCS="\
../../rtl/friscv_csr.sv \
../../rtl/friscv_registers.sv \
../../rtl/friscv_alu.sv \
../../rtl/friscv_control.sv \
../../rtl/friscv_decoder.sv \
../../rtl/friscv_memfy.sv \
../../rtl/friscv_processing.sv \
../../rtl/friscv_bus_perf.sv \
../../rtl/friscv_scfifo.sv \
../../rtl/friscv_ram.sv \
../../rtl/friscv_rambe.sv \
../../rtl/friscv_icache.sv \
../../rtl/friscv_dcache.sv \
../../rtl/friscv_cache_prefetcher.sv \
../../rtl/friscv_cache_io_fetcher.sv \
../../rtl/friscv_cache_block_fetcher.sv \
../../rtl/friscv_cache_ooo_mgt.sv \
../../rtl/friscv_cache_pusher.sv \
../../rtl/friscv_cache_flusher.sv \
../../rtl/friscv_cache_blocks.sv \
../../rtl/friscv_cache_memctrl.sv \
../../rtl/friscv_bit_sync.sv \
../../rtl/friscv_checkers.sv \
../../rtl/friscv_div.sv \
../../rtl/friscv_m_ext.sv \
../../rtl/friscv_pipeline.sv \
../../rtl/friscv_rv32i_core.sv \
../../rtl/friscv_axi_or_tracker.sv \
../../rtl/friscv_mpu.sv \
../../rtl/friscv_pmp_region.sv \
../../rtl/friscv_pulser.sv"

yosys -g -DARTY \
      -p "scratchpad -set xilinx_dsp.multonly 1" \
      -p "verilog_defaults -add -I../../rtl" \
      -p "read -define XLEN=32 -sv -I../../rtl $SRCS " \
      -p "synth_xilinx -nowidelut -flatten -abc9 -arch xc7 -top friscv_rv32i_core " \
      $SRCS | tee syn.log

exit

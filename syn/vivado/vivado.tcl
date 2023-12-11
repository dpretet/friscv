# Set the path to the source directory
set friscv_dir "../../rtl/"
set xbar_dir "../../dep/axi-crossbar/rtl/"
set top $env(TOP)
set part $env(PART)

file mkdir $top

# Create a new project
create_project $top ./$top -part $part -force

# Set the `define` to be passed to the code
set_property verilog_define {XLEN=32} [current_fileset]

# Crossbar sources
add_files [glob -directory $xbar_dir *.sv]

# FRISCV sources
read_verilog -sv "$friscv_dir/friscv_csr.sv"
read_verilog -sv "$friscv_dir/friscv_registers.sv"
read_verilog -sv "$friscv_dir/friscv_alu.sv"
read_verilog -sv "$friscv_dir/friscv_control.sv"
read_verilog -sv "$friscv_dir/friscv_decoder.sv"
read_verilog -sv "$friscv_dir/friscv_memfy.sv"
read_verilog -sv "$friscv_dir/friscv_processing.sv"
read_verilog -sv "$friscv_dir/friscv_bus_perf.sv"
read_verilog -sv "$friscv_dir/friscv_scfifo.sv"
read_verilog -sv "$friscv_dir/friscv_ram.sv"
read_verilog -sv "$friscv_dir/friscv_rambe.sv"
read_verilog -sv "$friscv_dir/friscv_icache.sv"
read_verilog -sv "$friscv_dir/friscv_dcache.sv"
read_verilog -sv "$friscv_dir/friscv_cache_io_fetcher.sv"
read_verilog -sv "$friscv_dir/friscv_cache_block_fetcher.sv"
read_verilog -sv "$friscv_dir/friscv_cache_prefetcher.sv"
read_verilog -sv "$friscv_dir/friscv_cache_ooo_mgt.sv"
read_verilog -sv "$friscv_dir/friscv_cache_pusher.sv"
read_verilog -sv "$friscv_dir/friscv_cache_flusher.sv"
read_verilog -sv "$friscv_dir/friscv_cache_blocks.sv"
read_verilog -sv "$friscv_dir/friscv_cache_memctrl.sv"
read_verilog -sv "$friscv_dir/friscv_bit_sync.sv"
read_verilog -sv "$friscv_dir/friscv_checkers.sv"
read_verilog -sv "$friscv_dir/friscv_div.sv"
read_verilog -sv "$friscv_dir/friscv_m_ext.sv"
read_verilog -sv "$friscv_dir/friscv_pipeline.sv"
read_verilog -sv "$friscv_dir/friscv_axi_or_tracker.sv"
read_verilog -sv "$friscv_dir/friscv_mpu.sv"
read_verilog -sv "$friscv_dir/friscv_pmp_region.sv"
read_verilog -sv "$friscv_dir/friscv_pulser.sv"
read_verilog -sv "$friscv_dir/friscv_rv32i_core.sv"
read_verilog -sv "$friscv_dir/friscv_rv32i_platform.sv"
read_verilog -sv "$friscv_dir/friscv_apb_interconnect.sv"
read_verilog -sv "$friscv_dir/friscv_clint.sv"
read_verilog -sv "$friscv_dir/friscv_gpios.sv"
read_verilog -sv "$friscv_dir/friscv_io_subsystem.sv"
read_verilog -sv "$friscv_dir/friscv_mem_router.sv"
read_verilog -sv "$friscv_dir/friscv_stats.sv"
read_verilog -sv "$friscv_dir/friscv_uart.sv"

import_files -force

import_files -fileset constrs_1 -force -norecurse ./constraints.xdc

update_compile_order -fileset sources_1

# Launch synthesis
synth_design -top $top -include_dirs $friscv_dir 

# Display area results
report_utilization

# Display timing closure results
report_timing_summary

exit

#=======================================================================
# Makefile for riscv-tests/isa
#-----------------------------------------------------------------------

XLEN ?= 64

src_dir := .
env_dir := ./env

ifeq ($(XLEN),64)
include $(src_dir)/rv64ui/Makefrag
endif
include $(src_dir)/rv32ui/Makefrag

default: all

#--------------------------------------------------------------------
# Build rules
#--------------------------------------------------------------------

RISCV_PREFIX ?= riscv64-unknown-elf-
RISCV_GCC ?= $(RISCV_PREFIX)gcc
RISCV_GCC_OPTS ?= -g -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles
RISCV_OBJDUMP ?= $(RISCV_PREFIX)objdump --disassemble-all --disassemble-zeroes --section=.text --section=.text.startup --section=.text.init --section=.data
RISCV_OBJCOPY = $(RISCV_PREFIX)objcopy
RISCV_SIM ?= spike

vpath %.S $(src_dir)

#------------------------------------------------------------
# Build assembly tests

%.asm: %
	$(RISCV_OBJDUMP) $<.elf > $@
	$(RISCV_OBJCOPY) -O verilog $<.elf $<.v

%.out: %
	$(RISCV_SIM) --isa=rv64gc $<.elf 2> $@

%.out32: %
	$(RISCV_SIM) --isa=rv32gc $<.elf 2> $@

define compile_template

$$($(1)_p_tests): $(1)-p-%: $(1)/%.S
	$$(RISCV_GCC) $(2) $$(RISCV_GCC_OPTS) -I$(env_dir) -I$(env_dir)/p -I$(src_dir)/macros/scalar -T$(env_dir)/p/link.ld $$< -o $$@.elf
$(1)_tests += $$($(1)_p_tests)

$$($(1)_v_tests): $(1)-v-%: $(1)/%.S
	$$(RISCV_GCC) $(2) $$(RISCV_GCC_OPTS) -DENTROPY=0x$$(shell echo \$$@ | md5sum | cut -c 1-7) -std=gnu99 -O2 -I$(env_dir) -I$(env_dir)/v -I$(src_dir)/macros/scalar -T$(env_dir)/v/link.ld $(env_dir)/v/entry.S $(env_dir)/v/*.c $$< -o $$@.elf
$(1)_tests += $$($(1)_v_tests)

$(1)_tests_dump = $$(addsuffix .asm, $$($(1)_tests))

$(1): $$($(1)_tests_dump)

.PHONY: $(1)

COMPILER_SUPPORTS_$(1) := $$(shell $$(RISCV_GCC) $(2) -c -x c /dev/null -o /dev/null 2> /dev/null; echo $$$$?)

ifeq ($$(COMPILER_SUPPORTS_$(1)),0)
tests += $$($(1)_tests)
endif

endef

$(eval $(call compile_template,rv32ui,-march=rv32g -mabi=ilp32))
ifeq ($(XLEN),64)
$(eval $(call compile_template,rv64ui,-march=rv64g -mabi=lp64))
endif

tests_dump = $(addsuffix .asm, $(tests))
tests_hex = $(addsuffix .hex, $(tests))
tests_out = $(addsuffix .out, $(filter rv64%,$(tests)))
tests32_out = $(addsuffix .out32, $(filter rv32%,$(tests)))

run: $(tests_out) $(tests32_out)

junk += $(tests) $(tests_dump) $(tests_hex) $(tests_out) $(tests32_out)

#------------------------------------------------------------
# Default

all: $(tests_dump)

#------------------------------------------------------------
# Clean up

clean:
	rm -rf $(junk)
	rm -fr *.elf
	rm -fr *.dump
	rm -fr *.gtkw
	rm -fr *.vcd

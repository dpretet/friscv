# Copyright 2018 Embedded Microprocessor Benchmark Consortium (EEMBC)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Original Author: Shay Gal-on

# Make sure the default target is to simply build and run the benchmark.
RSTAMP = v1.0

.PHONY: run score
run: $(OUTFILE) rerun score

score:
	@echo "Check run1.log and run2.log for results."
	@echo "See README.md for run and reporting rules."

PORT_DIR=barebones

vpath %.c $(PORT_DIR)
vpath %.S $(PORT_DIR)
vpath %.h $(PORT_DIR)
vpath %.mak $(PORT_DIR)
include $(PORT_DIR)/core_portme.mak

ITERATIONS=10

ifdef REBUILD
FORCE_REBUILD=force_rebuild
endif

# Select architecure and ABI
CFLAGS +=	-march=rv32im \
			-mabi=ilp32 \
			-O0 \
			-g \
			-I./ \
			-I./barebones \
			-I$(RISCV_CLIB) \
			-mcmodel=medany \
			-static \
			-std=gnu99 \

CFLAGS += -DITERATIONS=$(ITERATIONS)

CORE_FILES = core_list_join core_main core_matrix core_state core_util
ORIG_SRCS = $(addsuffix .c,$(CORE_FILES))
SRCS = $(ORIG_SRCS) $(PORT_SRCS)
OBJS = $(addprefix $(OPATH),$(addsuffix $(OEXT),$(CORE_FILES)) $(PORT_OBJS))
OUTNAME = coremark$(EXE)
OUTFILE = $(OPATH)$(OUTNAME)
LOUTCMD = $(OFLAG) $(OUTFILE) $(LFLAGS_END)
OUTCMD = $(OUTFLAG) $(OUTFILE) $(LFLAGS_END)
CRT = ./crt0.S

HEADERS = coremark.h
CHECK_FILES = $(ORIG_SRCS) $(HEADERS)

$(OPATH):
	$(MKDIR) $(OPATH)

.PHONY: compile link
ifdef SEPARATE_COMPILE
$(OPATH)$(PORT_DIR):
	$(MKDIR) $(OPATH)$(PORT_DIR)

compile: $(OPATH) $(OPATH)$(PORT_DIR) $(OBJS) $(HEADERS)
link: compile
	$(LD) $(LFLAGS) $(XLFLAGS) $(OBJS) $(LOUTCMD)
	@echo "Link NOT performed along with compile"

else

#$(PROJ_NAME).elf: compile

compile: $(OPATH) $(SRCS) $(HEADERS)
	$(RISCV_CC) -c $(CFLAGS) -o ctr0.o $(CRT) -D__ASSEMBLY__=1
	$(CC) $(CFLAGS) $(XCFLAGS) $(SRCS) ctr0.o $(OUTCMD) $(LDFLAGS)
link: compile
	@echo "Link performed along with compile"

endif

########################################################
all: $(OUTFILE)
	$(RISCV_OBJCOPY) -O ihex $(PROJ_NAME).elf $(PROJ_NAME).hex
	$(RISCV_OBJCOPY) -O binary $(PROJ_NAME).elf $(PROJ_NAME).bin
	$(RISCV_OBJCOPY) -O verilog $(PROJ_NAME).elf $(PROJ_NAME).v
	$(RISCV_OBJDUMP) -S -d $(PROJ_NAME).elf > $(PROJ_NAME).asm
	@cp *.v ../
	$(RISCV_NM) *.elf > $(PROJ_NAME).symbols
	@cp *.symbols ../
	@echo "done"
########################################################

$(OUTFILE): $(SRCS) $(HEADERS) Makefile core_portme.mak $(EXTRA_DEPENDS) $(FORCE_REBUILD)
	$(MAKE) port_prebuild
	$(MAKE) link
	$(MAKE) port_postbuild

.PHONY: rerun
rerun:
	$(MAKE) XCFLAGS="$(XCFLAGS) -DPERFORMANCE_RUN=1" load run1.log
	$(MAKE) XCFLAGS="$(XCFLAGS) -DVALIDATION_RUN=1" load run2.log

PARAM1=$(PORT_PARAMS) 0x0 0x0 0x66 $(ITERATIONS)
PARAM2=$(PORT_PARAMS) 0x3415 0x3415 0x66 $(ITERATIONS)
PARAM3=$(PORT_PARAMS) 8 8 8 $(ITERATIONS)

run1.log-PARAM=$(PARAM1) 7 1 2000
run2.log-PARAM=$(PARAM2) 7 1 2000
run3.log-PARAM=$(PARAM3) 7 1 1200

run1.log run2.log run3.log: load
	$(MAKE) port_prerun
	$(RUN) $(OUTFILE) $($(@)-PARAM) > $(OPATH)$@
	$(MAKE) port_postrun

.PHONY: gen_pgo_data
gen_pgo_data: run3.log

.PHONY: load
load: $(OUTFILE)
	$(MAKE) port_preload
	$(LOAD) $(OUTFILE)
	$(MAKE) port_postload

.PHONY: clean
clean:
	rm -f $(OUTFILE) $(OBJS) $(OPATH)*.log *.info $(OPATH)index.html $(PORT_CLEAN)
	rm -f *.elf $(PROJ_NAME) *.map *.bin *.md5 *.hex *.v *.asm *.symbols

.PHONY: force_rebuild
force_rebuild:
	echo "Forcing Rebuild"

.PHONY: check
check:
	md5sum -c coremark.md5

ifdef ETC
# Targets related to testing and releasing CoreMark. Not part of the general release!
include Makefile.internal
endif

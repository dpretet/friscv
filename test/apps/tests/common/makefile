# distributed under the mit license
# https://opensource.org/licenses/mit-license.php

PROJ_NAME=$(shell basename $(CURDIR))

RISCV_NAME = riscv64-unknown-elf
RISCV_CC=$(RISCV_NAME)-gcc
RISCV_OBJCOPY = $(RISCV_NAME)-objcopy
RISCV_OBJDUMP = $(RISCV_NAME)-objdump
RISCV_NM      = $(RISCV_NAME)-nm

RISCV_CLIB="/opt/homebrew/Cellar/riscv-gnu-toolchain/main/riscv64-unknown-elf/include/"

SRCS =	$(wildcard *.c) \
        $(wildcard *.h) \
        $(wildcard *.S)


# Select architecure and ABI
CFLAGS +=	-march=rv32im \
			-mabi=ilp32 \
			-O0 \
			-g \
			-I./ \
			-mcmodel=medany \
			-static \
			-std=gnu99 \

# -e_start: Specify that the program entry point is _start
# -nostartfiles: Do not use the standard system startup files when linking
# -Map: store memory map
# --print-memory-usage: print memory usage in the shell
# -nostdlib: Do not use the standard system startup files or libraries when linking
# -nolibc: Do not use the C library or system libraries tightly coupled with it when linking
LD = linker.ld
LDFLAGS +=	-nostartfiles \
			-e _start \
			-T $(LD) \
			-Wl,-Map,$(OBJDIR)/$(PROJ_NAME).map \
			-Wl,--print-memory-usage

OBJDIR = .
OBJS := $(SRCS)
OBJS := $(OBJS:.c=.o)
OBJS := $(OBJS:.S=.o)
OBJS := $(addprefix $(OBJDIR)/,$(OBJS))


all: $(OBJDIR)/$(PROJ_NAME).elf $(OBJDIR)/$(PROJ_NAME).hex $(OBJDIR)/$(PROJ_NAME).asm $(OBJDIR)/$(PROJ_NAME).v
	@cp *.v ../
	$(RISCV_NM) *.elf > $(PROJ_NAME).symbols
	@cp *.symbols ../
	@echo "done"

$(OBJDIR)/%.elf: $(OBJS) | $(OBJDIR)
	$(RISCV_CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

%.hex: %.elf
	$(RISCV_OBJCOPY) -O ihex $^ $@

%.bin: %.elf
	$(RISCV_OBJCOPY) -O binary $^ $@

%.v: %.elf
	$(RISCV_OBJCOPY) -O verilog $^ $@

%.asm: %.elf
	$(RISCV_OBJDUMP) -S -d $^ > $@

$(OBJDIR)/%.o: %.c
	$(RISCV_CC) -c $(CFLAGS) -o $@ $^

$(OBJDIR)/%.o: %.S
	$(RISCV_CC) -c $(CFLAGS) -o $@ $^ -D__ASSEMBLY__=1

$(OBJDIR):
	mkdir -p $@

clean:
	rm -f $(OBJDIR)/*.elf
	rm -f $(OBJDIR)/*.hex
	rm -f $(OBJDIR)/*.map
	rm -f $(OBJDIR)/*.v
	rm -f $(OBJDIR)/*.asm
	rm -f $(OBJDIR)/*.o
	rm -f $(OBJDIR)/*.su

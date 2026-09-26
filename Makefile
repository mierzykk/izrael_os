SHELL := /bin/bash

# ============================================================
# Toolchain
# BIOS / bare-metal x86-64 project
# ============================================================
CC      ?= gcc
NASM      ?= nasm
OBJCOPY ?= objcopy
QEMU    ?= qemu-system-x86_64

KCC := $(shell if command -v x86_64-elf-gcc >/dev/null 2>&1; then echo x86_64-elf-gcc; else echo $(CC); fi)
KLD := $(shell if command -v x86_64-elf-ld >/dev/null 2>&1; then echo x86_64-elf-ld; else echo ld; fi)

# ============================================================
# Directories / outputs
# ============================================================
BUILD_DIR ?= build

BOOT_BIN   := $(BUILD_DIR)/boot.bin
KERNEL_ELF := $(BUILD_DIR)/kernel.elf
KERNEL_BIN := $(BUILD_DIR)/kernel.bin
USER_INIT  := $(BUILD_DIR)/user/init.elf
OS_IMAGE   := $(BUILD_DIR)/os.img

# Kernel is loaded by the BIOS bootloader at this physical address.
KERNEL_LOAD_ADDR ?= 0x8000
KERNEL_LBA       ?= 1
IMAGE_SIZE       ?= 128M
QEMU_MEM         ?= 512M
QEMU_CPU         ?= qemu64
QEMU_MACHINE     ?= pc

VNC_DISPLAY ?= 1
VNC_VIEWER  ?= /mnt/c/Program Files/TigerVNC/vncviewer.exe

# ============================================================
# Source discovery
# Keep your existing directory layout.
# Do NOT compile the AArch64 tree into the x86-64 kernel.
# boot/entry.asm is the 64-bit kernel entry.
# ============================================================
KERNEL_C := $(shell find kernel drivers -type f -name '*.c' \
             ! -path 'kernel/arch/aarch64/*' 2>/dev/null | sort)

KERNEL_ASM := $(shell find kernel drivers -type f -name '*.asm' \
               ! -path 'kernel/arch/aarch64/*' 2>/dev/null | sort)

# 64-bit entry point belonging to the kernel.
KERNEL_ASM += boot/entry.asm

INIT_C := $(shell find user/init user/libc -type f -name '*.c' 2>/dev/null | sort)
INIT_ASM := $(shell find user/init user/libc -type f -name '*.asm' 2>/dev/null | sort)

KERNEL_OBJS := $(patsubst %.c,$(BUILD_DIR)/%.o,$(KERNEL_C)) \
               $(patsubst %.asm,$(BUILD_DIR)/%.o,$(KERNEL_ASM))

INIT_OBJS := $(patsubst %.c,$(BUILD_DIR)/%.o,$(INIT_C)) \
             $(patsubst %.asm,$(BUILD_DIR)/%.o,$(INIT_ASM))

# ============================================================
# Flags
# ============================================================
WARNFLAGS = -Wall -Wextra
DEPFLAGS  = -MMD -MP

# Kernel C: freestanding x86-64.
KCFLAGS = -m64 -O2 -g \
          -ffreestanding \
          -fno-stack-protector \
          -fno-stack-check \
          -fno-builtin \
          -fno-pie -fno-pic \
          -fno-asynchronous-unwind-tables \
          -fno-unwind-tables \
          -fno-stack-clash-protection \
          -mno-red-zone \
          -mno-mmx \
          -mno-sse \
          -mno-sse2 \
          -mcmodel=small \
          $(WARNFLAGS) $(DEPFLAGS) \
          -Iinclude -Ikernel/include -Ikernel/lib/include

# User space is freestanding too, but is built separately.
UCFLAGS = -m64 -O2 -g \
          -ffreestanding \
          -fno-stack-protector \
          -fno-stack-check \
          -fno-builtin \
          -fno-pie -fno-pic \
          -mno-red-zone \
          $(WARNFLAGS) $(DEPFLAGS) \
          -Iinclude -Iuser/libc

ASFLAGS      = -f elf64
BOOT_ASFLAGS = -f bin

# ============================================================
# Kernel linker
# ============================================================
KERNEL_ENTRY ?= entry
KERNEL_LDS   ?= linker.ld

KERNEL_LIBGCC := $(shell $(KCC) -print-libgcc-file-name 2>/dev/null)

KERNEL_LDFLAGS = -T $(KERNEL_LDS) \
                 -nostdlib \
                 -e $(KERNEL_ENTRY) \
                 -z max-page-size=0x1000

USER_ENTRY ?= _start
USER_LDS   ?= user/linker.ld

USER_LDFLAGS = -nostdlib \
               -e $(USER_ENTRY) \
               -z max-page-size=0x1000

# ============================================================
# QEMU
# Legacy BIOS / SeaBIOS.
# No OVMF, no UEFI, no GNU-EFI.
# ============================================================
QEMU_COMMON = -machine $(QEMU_MACHINE) \
              -m $(QEMU_MEM) \
              -cpu $(QEMU_CPU) \
              -drive format=raw,file=$(OS_IMAGE),if=ide,index=0,media=disk \
              -no-reboot \
              -no-shutdown

# ============================================================
# Targets
# ============================================================
.PHONY: all build boot kernel init image run nog qemu-debug \
        clean check-tools help test

all: image
build: all

boot: check-tools $(BOOT_BIN)

kernel: check-tools $(KERNEL_ELF) $(KERNEL_BIN)

init: check-tools $(if $(strip $(INIT_OBJS)),$(USER_INIT),)

image: check-tools $(OS_IMAGE)

# ============================================================
# Environment checks
# ============================================================
check-tools:
	@for t in $(KCC) $(KLD) $(NASM) $(OBJCOPY) $(QEMU) $(CC) dd truncate stat; do \
		command -v "$$t" >/dev/null 2>&1 || { \
			echo "ERROR: brak narzedzia: $$t"; \
			exit 1; \
		}; \
	done

	@test -f "$(KERNEL_LDS)" || { \
		echo "ERROR: brak $(KERNEL_LDS)"; \
		exit 1; \
	}

	@if [ -z "$(strip $(KERNEL_OBJS))" ]; then \
		echo "ERROR: brak zrodel kernela w kernel/ lub drivers/ oraz boot/entry.asm"; \
		exit 1; \
	fi

test: check-tools
	@echo "=== OSV3 BIOS build environment ==="
	@echo "KCC:      $(KCC)"
	@echo "KLD:      $(KLD)"
	@echo "NASM:     $(NASM)"
	@echo "QEMU:     $(QEMU)"
	@echo "Machine:  $(QEMU_MACHINE)"
	@echo "Kernel:   $(KERNEL_LOAD_ADDR)"
	@echo "Image:    $(OS_IMAGE) ($(IMAGE_SIZE))"
	@echo "OK"

# ============================================================
# Kernel C
# ============================================================
$(BUILD_DIR)/kernel/%.o: kernel/%.c
	@mkdir -p $(dir $@)
	$(KCC) $(KCFLAGS) -c $< -o $@

# ============================================================
# Kernel ASM
# ============================================================
$(BUILD_DIR)/kernel/%.o: kernel/%.asm
	@mkdir -p $(dir $@)
	$(NASM) $(ASFLAGS) $< -o $@

# ============================================================
# Drivers
# ============================================================
$(BUILD_DIR)/drivers/%.o: drivers/%.c
	@mkdir -p $(dir $@)
	$(KCC) $(KCFLAGS) -c $< -o $@

$(BUILD_DIR)/drivers/%.o: drivers/%.asm
	@mkdir -p $(dir $@)
	$(NASM) $(ASFLAGS) $< -o $@

# ============================================================
# 64-bit kernel entry
# ============================================================
$(BUILD_DIR)/boot/entry.o: boot/entry.asm
	@mkdir -p $(dir $@)
	$(NASM) $(ASFLAGS) $< -o $@

# ============================================================
# Kernel ELF
# ============================================================
$(KERNEL_ELF): $(KERNEL_OBJS) $(KERNEL_LDS)
	@mkdir -p $(dir $@)
	$(KLD) $(KERNEL_LDFLAGS) \
		-o $@ \
		$(KERNEL_OBJS) \
		$(KERNEL_LIBGCC)

# ELF -> flat binary
$(KERNEL_BIN): $(KERNEL_ELF)
	@mkdir -p $(dir $@)
	$(OBJCOPY) -O binary $< $@

# ============================================================
# BIOS boot sector
#
# boot.asm is assembled as raw binary.
# NASM receives kernel size/address as defines.
#
# Your boot.asm must actually use:
#   KERNEL_LBA
#   KERNEL_SECTORS
#   KERNEL_LOAD_ADDR
#
# to read the kernel from disk.
# ============================================================
$(BOOT_BIN): boot/boot.asm $(KERNEL_BIN)
	@mkdir -p $(dir $@)
	@sectors=$$(( ($$(stat -c%s "$(KERNEL_BIN)") + 511) / 512 )); \
		echo "Building BIOS boot sector (kernel=$$sectors sectors)..."; \
		$(NASM) $(BOOT_ASFLAGS) \
			-dKERNEL_LBA=$(KERNEL_LBA) \
			-dKERNEL_SECTORS=$$sectors \
			-dKERNEL_LOAD_ADDR=$(KERNEL_LOAD_ADDR) \
			boot/boot.asm -o $@; \
		bytes=$$(stat -c%s "$@"); \
		if [ "$$bytes" -gt 512 ]; then \
			echo "ERROR: boot.bin ma $$bytes bajtow; maksymalnie 512."; \
			exit 1; \
		fi

# ============================================================
# User init
# ============================================================
ifeq ($(strip $(INIT_OBJS)),)

$(USER_INIT):
	@mkdir -p $(dir $@)
	@echo "Brak zrodel w user/init lub user/libc; init.elf nie jest jeszcze budowane."
	@rm -f $@

else

$(USER_INIT): $(INIT_OBJS)
	@mkdir -p $(dir $@)
	@if [ -f "$(USER_LDS)" ]; then \
		$(KLD) $(USER_LDFLAGS) \
			-T "$(USER_LDS)" \
			-o $@ \
			$(INIT_OBJS) \
			$(KERNEL_LIBGCC); \
	else \
		$(KLD) $(USER_LDFLAGS) \
			-o $@ \
			$(INIT_OBJS) \
			$(KERNEL_LIBGCC); \
	fi

endif

$(BUILD_DIR)/user/%.o: user/%.c
	@mkdir -p $(dir $@)
	$(KCC) $(UCFLAGS) -c $< -o $@

$(BUILD_DIR)/user/%.o: user/%.asm
	@mkdir -p $(dir $@)
	$(NASM) $(ASFLAGS) $< -o $@

# ============================================================
# Raw BIOS disk image
#
# Sector 0 : boot.bin
# Sector 1+: kernel.bin
# ============================================================
$(OS_IMAGE): $(BOOT_BIN) $(KERNEL_BIN)
	@mkdir -p $(dir $@)
	@rm -f $@
	truncate -s $(IMAGE_SIZE) $@
	dd if="$(BOOT_BIN)" of="$@" \
		bs=512 count=1 \
		conv=notrunc status=none
	dd if="$(KERNEL_BIN)" of="$@" \
		bs=512 seek=$(KERNEL_LBA) \
		conv=notrunc status=none

	@echo "Created $(OS_IMAGE)"
	@echo "  boot   : sector 0"
	@echo "  kernel : LBA $(KERNEL_LBA)"
	@echo "  kernel RAM address : $(KERNEL_LOAD_ADDR)"

# ============================================================
# Run with VNC
# ============================================================
run: check-tools $(OS_IMAGE)
	@set -e; \
	$(QEMU) $(QEMU_COMMON) \
		-display vnc=127.0.0.1:$(VNC_DISPLAY) \
		-serial stdio & \
	pid=$$!; \
	trap 'kill $$pid 2>/dev/null || true' EXIT INT TERM; \
	sleep 1; \
	if [ -f "$(VNC_VIEWER)" ]; then \
		"$(VNC_VIEWER)" 127.0.0.1:$(VNC_DISPLAY); \
	else \
		echo "Brak VNC viewer: $(VNC_VIEWER)"; \
		echo "QEMU dziala na 127.0.0.1:590$(VNC_DISPLAY)"; \
		wait $$pid; \
	fi

# ============================================================
# Headless / serial
# ============================================================
nog: check-tools $(OS_IMAGE)
	$(QEMU) $(QEMU_COMMON) \
		-display none \
		-serial stdio \
		-monitor none

# ============================================================
# QEMU + GDB
# ============================================================
qemu-debug: check-tools $(OS_IMAGE)
	$(QEMU) $(QEMU_COMMON) \
		-display none \
		-serial stdio \
		-monitor none \
		-s -S

# ============================================================
# Cleanup / help
# ============================================================
clean:
	rm -rf $(BUILD_DIR)

help:
	@echo "make             -> build boot sector + kernel + build/os.img"
	@echo "make test        -> check toolchain"
	@echo "make boot        -> build BIOS boot sector"
	@echo "make kernel      -> build kernel.elf + kernel.bin"
	@echo "make image       -> build raw BIOS disk image"
	@echo "make run         -> QEMU + VNC"
	@echo "make nog         -> QEMU headless + serial"
	@echo "make qemu-debug  -> QEMU paused + GDB on localhost:1234"
	@echo "make init        -> optional user/init build"
	@echo "make clean       -> remove build/"

-include $(KERNEL_OBJS:.o=.d) $(INIT_OBJS:.o=.d)
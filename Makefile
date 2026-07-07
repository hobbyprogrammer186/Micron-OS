BUILD_DIR=build
INCLUDE_DIR=$(CURDIR)/include
ASM=nasm
ASFLAGS=-d$(LANGUAGE) -i $(INCLUDE_DIR) -f bin
CC=gcc
CFLAGS=-ffreestanding -nostdlib -m32 -I$(INCLUDE_DIR)
LD=ld
LANGUAGE=en_us

ASMObjects = $(PRE_INCLUDE_SOURCES)
OBJ =

include drivers/video/Makefile
include kernel/Makefile

all: postBuild micron

postBuild:
	@echo "=============="
	@echo "    Kernel"
	@echo "=============="
	@mkdir -p $(BUILD_DIR)

SOURCES_C := $(shell find kernel -name '*.c')
SOURCES_ASM := $(shell find kernel -name '*.asm')
SOURCES_DRIVERS_ASM := $(shell find drivers -name '*.asm')
ALL_ASM_SOURCES := $(SOURCES_ASM) $(SOURCES_DRIVERS_ASM)
BUILD_OBJS := $(patsubst kernel/%.c,$(BUILD_DIR)/kernel/%.o,$(SOURCES_C)) \
		$(patsubst kernel/%.asm,$(BUILD_DIR)/kernel/%.obj,$(SOURCES_ASM)) \
		$(patsubst drivers/%.asm,$(BUILD_DIR)/drivers/%.obj,$(SOURCES_DRIVERS_ASM))

PRE_INCLUDE_SOURCES := $(filter-out kernel/kernel.asm,$(ALL_ASM_SOURCES))

NASM_PRE_INCLUDES := $(patsubst %, -p %, $(PRE_INCLUDE_SOURCES))

micron: $(BUILD_OBJS)
ifeq ($(LINT),1)
	@echo "  LINT Assembly Files..."
	@for src in $(PRE_INCLUDE_SOURCES) kernel/kernel.asm; do \
		echo "  LINT $$src"; \
		$(ASM) -i $(INCLUDE_DIR) -d$(LANGUAGE) -dDUMMY_BUILD $(ASFLAGS) $$src -o /dev/null 2>&1; \
		if [ $$? -ne 0 ]; then exit 1; fi; \
	done
	@echo "  LINT Complete (No Errors)"
else
	@echo "  LD $(BUILD_DIR)/$@"
	@$(ASM) -i $(INCLUDE_DIR) -d$(LANGUAGE) $(ASFLAGS) $(NASM_PRE_INCLUDES) kernel/kernel.asm -o $(BUILD_DIR)/$@.tmp
	@$(ASM) -i $(INCLUDE_DIR) -d$(LANGUAGE) -dSIZE=$$(stat -c %s $(BUILD_DIR)/$@.tmp) -dKERNEL $(ASFLAGS) $(NASM_PRE_INCLUDES) kernel/kernel.asm -o $(BUILD_DIR)/$@
	@rm -rf $(BUILD_DIR)/$@.tmp
endif

$(BUILD_DIR)/kernel/%.obj: kernel/%.asm
	@echo "  AS $@"
#	@mkdir -p $(dir $@)

$(BUILD_DIR)/%.obj: kernel/%.asm
	@echo "  AS $@"
#	@mkdir -p $(dir $@)

$(BUILD_DIR)/drivers/%.obj: drivers/%.asm
	@echo "  AS $@"
#	@mkdir -p $(dir $@)

$(BUILD_DIR)/%.obj: drivers/%.asm
	@echo "  AS $@"
#	@mkdir -p $(dir $@)

clean:
	@rm -rf $(BUILD_DIR)

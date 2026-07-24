BUILD_DIR_RELATIVE=build
BUILD_DIR=$(CURDIR)/$(BUILD_DIR_RELATIVE)
INCLUDE_DIR=$(CURDIR)/include
ASM=nasm
ASFLAGS=-d$(LANGUAGE) -i $(INCLUDE_DIR) -f bin
LANGUAGE=en_us
SOURCE_DIR=$(CURDIR)

ASMObjects = $(PRE_INCLUDE_SOURCES)
OBJ =

include drivers/video/Makefile
include kernel/Makefile

all: postBuild micron afterKernel

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
	@echo "  LD $(BUILD_DIR_RELATIVE)/$@"
	@$(ASM) -i $(INCLUDE_DIR) -d$(LANGUAGE) $(ASFLAGS) $(NASM_PRE_INCLUDES) kernel/kernel.asm -o $(BUILD_DIR)/$@.tmp
	@$(ASM) -i $(INCLUDE_DIR) -d$(LANGUAGE) -dSIZE=$$(stat -c %s $(BUILD_DIR)/$@.tmp) -dKERNEL $(ASFLAGS) $(NASM_PRE_INCLUDES) kernel/kernel.asm -o $(BUILD_DIR)/$@
	@rm -rf $(BUILD_DIR)/$@.tmp
endif

$(BUILD_DIR)/kernel/%.obj: kernel/%.asm
	@echo "  AS $(BUILD_DIR_RELATIVE)/kernel/$*.obj"
#	@mkdir -p $(dir $@)

$(BUILD_DIR)/%.obj: kernel/%.asm
	@echo "  AS $(BUILD_DIR_RELATIVE)/$*.obj"
#	@mkdir -p $(dir $@)

$(BUILD_DIR)/drivers/%.obj: drivers/%.asm
	@echo "  AS $(BUILD_DIR_RELATIVE)/drivers/$*.obj"
#	@mkdir -p $(dir $@)

$(BUILD_DIR)/%.obj: drivers/%.asm
	@echo "  AS $(BUILD_DIR_RELATIVE)/$*.obj"
#	@mkdir -p $(dir $@)

afterKernel:
	@$(MAKE) -C $(CURDIR)/boot

debug: all
	@echo "  QEMU $(BUILD_DIR_RELATIVE)/micron.img (GDB :1234)"
	qemu-system-x86_64 -fda $(BUILD_DIR_RELATIVE)/micron.img -boot a -m 32 -s -S

debug-bochs: all
	@echo "  BX $(BUILD_DIR_RELATIVE)/micron.img"
	bochs -f bochsrc -q

clean:
	@rm -rf $(BUILD_DIR)

export BUILD_DIR ASM ASFLAGS LANGUAGE SOURCE_DIR
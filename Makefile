BUILD_DIR=$(CURDIR)/build
INCLUDE_DIR=$(CURDIR)/include
ASM=nasm
ASFLAGS=-d$(LANGUAGE) -i $(INCLUDE_DIR) -f bin
CC=gcc
CFLAGS=-ffreestanding -nostdlib -m32 -I$(INCLUDE_DIR)
LD=ld
LANGUAGE=en_us

ASMObjects =
OBJ =

include drivers/video/Makefile
include kernel/Makefile

all: postBuild micron

postBuild:
	@mkdir -p $(BUILD_DIR)


SOURCES_C := $(shell find kernel -name '*.c')
SOURCES_ASM := $(shell find kernel -name '*.asm')
BUILD_OBJS := $(patsubst kernel/%.c,$(BUILD_DIR)/kernel/%.o,$(SOURCES_C)) \
		$(patsubst kernel/%.asm,$(BUILD_DIR)/kernel/%.obj,$(SOURCES_ASM))

micron: $(BUILD_OBJS)
	@echo "  LD $(BUILD_DIR)/$@"
	@$(ASM) $(ASFLAGS) $(ASMObjects) -o $(BUILD_DIR)/$@
#	@$(ASM) -f bin -o $(BUILD_DIR)/$@ $^

$(BUILD_DIR)/kernel/%.obj: kernel/%.asm
	@echo "  AS $@"
	@mkdir -p $(dir $@)
	$(eval ASMObjects += $<)
#	@$(ASM) $(ASFLAGS) $< -o $@

$(BUILD_DIR)/%.obj: kernel/%.asm
	@echo "  AS $@"
	@mkdir -p $(dir $@)
	$(eval ASMObjects += $<)
#	@$(ASM) $(ASFLAGS) $< -o $@

$(BUILD_DIR)/drivers/%.obj: drivers/%.asm
	@echo "  AS $@"
	@mkdir -p $(dir $@)
	$(eval ASMObjects += $<)
#	@$(ASM) -i $(INCLUDE_DIR) $(ASFLAGS) $< -o $@

$(BUILD_DIR)/%.obj: drivers/%.asm
	@echo "  AS $@"
	@mkdir -p $(dir $@)
	$(eval ASMObjects += $<)
#	@$(ASM) -i $(INCLUDE_DIR) $(ASFLAGS) $< -o $@

clean:
#	@find . \( -name '*.img' -o -name '*.mcxe' -o -name '*.mlib' -o -name '*.bin' -o -name '*.obj' -o -name '*.o' -o -name 'micron' \) -delete
	@rm -rf $(BUILD_DIR)
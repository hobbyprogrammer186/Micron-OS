build:
	@echo "=============="
	@echo "  Bootloader"
	@echo "=============="
	@$(ASM) $(ASFLAGS) $(SOURCE_DIR)/boot/floppyboot.asm -o $(BUILD_DIR)/floppyboot.bin
	@$(ASM) $(ASFLAGS) -i $(BUILD_DIR) $(SOURCE_DIR)/boot/image.asm -o $(BUILD_DIR)/micron.img
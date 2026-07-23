;
; Copyright (C) 2026 First Person
;
; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.
;

%include "definations.asm"
%include "languages.asm"

%ifdef DUMMY_BUILD
%include "dummy/mm.asm"
%include "dummy/kernel.asm"
%endif

bits 16

; ============================================================
; VBE Memory Models (ModeInfoBlock.MemoryModel)
; ============================================================
%define MEM_MODEL_TEXT            0x00
%define MEM_MODEL_CGA             0x01
%define MEM_MODEL_HERCULES        0x02
%define MEM_MODEL_PLANAR          0x03
%define MEM_MODEL_PACKED_PIXEL    0x04
%define MEM_MODEL_NON_CHAIN_256   0x05
%define MEM_MODEL_DIRECT_COLOR    0x06
%define MEM_MODEL_YUV             0x07
%define MEM_MODEL_XGA_DIRECT      0x08

; ============================================================
; VBE Capabilities (VesaInfoBlock.Capabilities bits)
; ============================================================
%define CAP_DAC_WIDTH         0x01
%define CAP_NOT_VGA           0x02
%define CAP_RAMDAC            0x04
%define CAP_STEREOSCOPIC      0x08
%define CAP_STEREO_VESA       0x10
%define CAP_EDID              0x20

; ============================================================
; Mode Attributes bits (ModeInfoBlock.ModeAttributes)
; ============================================================
%define MODE_ATTR_AVAILABLE       0x0001
%define MODE_ATTR_OPTIONAL_INFO   0x0002
%define MODE_ATTR_COLOR           0x0008
%define MODE_ATTR_GRAPHICS        0x0010
%define MODE_ATTR_NOT_VGA         0x0020
%define MODE_ATTR_NOT_WINDOWED    0x0040
%define MODE_ATTR_LFB             0x0080
%define MODE_ATTR_DOUBLE_SCAN     0x0100
%define MODE_ATTR_INTERLACED      0x0200
%define MODE_ATTR_HARDWARE_TRIPLE 0x0400
%define MODE_ATTR_STEREO          0x0800
%define MODE_ATTR_STEREO_STANDARD 0x1000

; ============================================================
; DPMS States
; ============================================================
%define DPMS_ON                  0x00
%define DPMS_STANDBY             0x01
%define DPMS_SUSPEND             0x02
%define DPMS_OFF                 0x04
%define DPMS_REDUCED_ON          0x08

; ============================================================
; VBE Save/Restore State subfunctions
; ============================================================
%define SR_STATE_SAVE            0x0000
%define SR_STATE_RESTORE         0x0001
%define SR_STATE_SIZE            0x0002
%define SR_STATE_SET             0x0003

; ============================================================
; VBE State save/restore flags (for VBESaveRestoreState)
; ============================================================
%define SRF_HARDWARE             0x0001
%define SRF_BIOS                 0x0002
%define SRF_DAC                  0x0004
%define SRF_REGISTERS            0x0008
%define SRF_ALL                  0x000F

; ============================================================
; VBE Controller Info Block (512 bytes)
; VBE 2.0+ with VBE 3.0 extended fields
; ============================================================
struc VesaInfoBlock
	.Signature              resb 4
	.Version                resw 1
	.OEMNamePtr             resd 1
	.Capabilities           resd 1
	.VideoModesOffset       resw 1
	.VideoModesSegment      resw 1
	.CountOf64KBlocks       resw 1
	.OEMSoftwareRevision    resw 1
	.OEMVendorNamePtr       resd 1
	.OEMProductNamePtr      resd 1
	.OEMProductRevisionPtr  resd 1
	; VBE 3.0 extended fields (within 222-byte Reserved area)
	.Vbe2Reserved           resb 12
	.MaxMode                resw 1
	.StartModeNumber        resw 1
	.Reserved               resb 206
	.OEMData                resb 256
endstruc

; ============================================================
; Mode Info Block (256 bytes)
; VBE 2.0+ with VBE 3.0 linear framebuffer fields
; ============================================================
struc ModeInfoBlock
	.ModeAttributes         resw 1
	.WinAAttributes         resb 1
	.WinBAttributes         resb 1
	.WinGranularity         resw 1
	.WinSize                resw 1
	.WinASegment            resw 1
	.WinBSegment            resw 1
	.WinFuncPtr             resd 1
	.BytesPerScanLine       resw 1
	.XResolution            resw 1
	.YResolution            resw 1
	.XCharSize              resb 1
	.YCharSize              resb 1
	.NumberOfPlanes         resb 1
	.BitsPerPixel           resb 1
	.NumberOfBanks          resb 1
	.MemoryModel            resb 1
	.BankSize               resb 1
	.NumberOfImagePages     resb 1
	.Reserved1              resb 1
	.RedMaskSize            resb 1
	.RedFieldPosition       resb 1
	.GreenMaskSize          resb 1
	.GreenFieldPosition     resb 1
	.BlueMaskSize           resb 1
	.BlueFieldPosition      resb 1
	.RsvdMaskSize           resb 1
	.RsvdFieldPosition      resb 1
	.DirectColorModeInfo    resb 1
	.PhysBasePtr            resd 1
	.OffScreenMemOffset     resd 1
	.OffScreenMemSize       resw 1
	.LinBytesPerScanLine    resw 1
	.BnkNumberOfImagePages  resb 1
	.LinNumberOfImagePages  resb 1
	.LinRedMaskSize         resb 1
	.LinRedFieldPosition    resb 1
	.LinGreenMaskSize       resb 1
	.LinGreenFieldPosition  resb 1
	.LinBlueMaskSize        resb 1
	.LinBlueFieldPosition   resb 1
	.LinRsvdMaskSize        resb 1
	.LinRsvdFieldPosition   resb 1
	.MaxPixelClock          resd 1
	.Reserved2              resb 190
endstruc

; ============================================================
; EDID block size (128 bytes per block)
; ============================================================
%define EDID_BLOCK_SIZE         128

; ============================================================
; checkVBEResult: Check VBE BIOS return status
; -Input-
; ax: return value from int 0x10 VBE call
; -Output-
; ax: system code (SYSTEM_CODE_SUCCESS on success)
; carry: clear on success, set on error
; ============================================================
checkVBEResult:
	cmp al, 0x4F
	jne .noVBE

	cmp ah, 0x00
	je .success
	cmp ah, 0x01
	je .hwFail
	cmp ah, 0x02
	je .notSupported
	cmp ah, 0x03
	je .badMode

	mov ax, SYSTEM_CODE_ERROR_UNKNOWN
	stc
	ret

.success:
	mov ax, SYSTEM_CODE_SUCCESS
	clc
	ret

.noVBE:
	mov ax, SYSTEM_CODE_ERROR_NO_VBE_SUPPORT
	stc
	ret

.hwFail:
	mov ax, SYSTEM_CODE_ERROR_VBE_SWITCH_FAILED
	stc
	ret

.notSupported:
	mov ax, SYSTEM_CODE_ERROR_VBE_HW_MISMATCH
	stc
	ret

.badMode:
	mov ax, SYSTEM_CODE_ERROR_VBE_INVALID_MODE
	stc
	ret

; ============================================================
; VBEGetControllerInfo: Get VBE controller information
; Tries VBE 3.0 signature first, falls back to VBE 2.0
; Fills VESABuffer with VesaInfoBlock data
; -Output-
; ax: system code
; ============================================================
VBEGetControllerInfo:
	push di
	push es

	push cs
	pop es
	mov di, VESABuffer

	mov dword [es:di], 'VBE3'
	mov ax, 0x4F00
	int 0x10
	cmp al, 0x4F
	jne .tryVBE2
	cmp dword [es:di], 'VESA'
	je .done

.tryVBE2:
	mov dword [es:di], 'VBE2'
	mov ax, 0x4F00
	int 0x10
	cmp al, 0x4F
	jne .fail
	cmp dword [es:di], 'VESA'
	je .done

.fail:
	mov ax, SYSTEM_CODE_ERROR_NO_VBE_SUPPORT
	stc
	pop es
	pop di
	ret

.done:
	pop es
	pop di
	mov ax, SYSTEM_CODE_SUCCESS
	clc
	ret

; ============================================================
; supportedVersionOfVBE: Detect VBE version support
; -Output-
; ax: 0 = no VBE, 2 = VBE 2.0, 3 = VBE 3.0+
; ============================================================
supportedVersionOfVBE:
	push di
	push es

	push cs
	pop es
	mov di, VESABuffer

	mov dword [es:di], 'VBE3'
	mov ax, 0x4F00
	int 0x10
	cmp al, 0x4F
	jne .checkV2

	cmp dword [es:di], 'VESA'
	jne .checkV2

	mov ax, [es:di + VesaInfoBlock.Version]
	cmp ax, 0x0300
	jl .checkV2

	pop es
	pop di
	mov ax, 3
	ret

.checkV2:
	mov dword [es:di], 'VBE2'
	mov ax, 0x4F00
	int 0x10
	cmp al, 0x4F
	jne .noSupport

	cmp dword [es:di], 'VESA'
	jne .noSupport

	pop es
	pop di
	mov ax, 2
	ret

.noSupport:
	pop es
	pop di
	xor ax, ax
	ret

; ============================================================
; VBEGetVersion: Get precise VBE version BCD value
; -Output-
; ax: system code
; bx: VBE version in BCD (e.g., 0x0300 for VBE 3.0)
; ============================================================
VBEGetVersion:
	call VBEGetControllerInfo
	cmp ax, SYSTEM_CODE_SUCCESS
	jne .fail

	mov bx, [VESABuffer + VesaInfoBlock.Version]
	clc
	ret

.fail:
	xor bx, bx
	stc
	ret

; ============================================================
; VBEGetModeInfo: Get information about a specific VBE mode
; Fills ModeInfoBuffer with ModeInfoBlock data
; -Input-
; cx: mode number
; -Output-
; ax: system code
; ============================================================
VBEGetModeInfo:
	push di
	push es

	push cs
	pop es
	mov di, ModeInfoBuffer
	mov ax, 0x4F01
	int 0x10

	call checkVBEResult

	pop es
	pop di
	ret

; ============================================================
; VBEGetInfo: Get mode info (backward-compatible wrapper)
; -Input-
; cx: mode number (0 to use current RESULATION)
; -Output-
; ax: system code
; ============================================================
VBEGetInfo:
	cmp cx, 0
	jne .haveMode
	mov cx, [RESULATION]

.haveMode:
	call VBEGetModeInfo
	cmp ax, SYSTEM_CODE_SUCCESS
	je .done

	push bx
	xor bx, bx
	call log
	pop bx

.done:
	ret

; ============================================================
; VBESetMode: Set a VBE video mode (low-level)
; Must be called from real mode (switchMode(0) first)
; -Input-
; bx: mode number (bit 14 = 1 for LFB)
; -Output-
; ax: system code
; ============================================================
VBESetMode:
	mov ax, 0x4F02
	xor di, di
	int 0x10

	jmp checkVBEResult

; ============================================================
; changeResulation: Set a VBE video mode (main entry)
; Handles real/protected mode transition internally
; -Input-
; ax: mode number (will set bit 14 for LFB)
; -Output-
; ax: system code
; ============================================================
changeResulation:
	push bp
	mov bp, sp
	push ax

	call supportedVersionOfVBE
	cmp ax, 2
	jl .noSupport

	mov ax, [bp - 2]
	cmp ax, 0
	je .invalidMode

	mov ax, 0
	call switchMode

	mov bx, [bp - 2]
	or bx, 0x4000
	call VBESetMode

	push ax

	mov ax, 1
	call switchMode

	pop ax

	cmp ax, SYSTEM_CODE_SUCCESS
	jne .setFailed

	mov bx, [bp - 2]
	mov [RESULATION], bx

.setFailed:
	pop ax
	pop bp
	ret

.noSupport:
	mov ax, SYSTEM_CODE_ERROR_NO_VBE_SUPPORT
	mov bx, RES_CHNG_INCAP
	call log
	pop ax
	pop bp
	ret

.invalidMode:
	mov ax, SYSTEM_CODE_ERROR_VBE_INVALID_MODE
	push bx
	xor bx, bx
	call log
	pop bx
	pop ax
	pop bp
	ret

; ============================================================
; VBEGetCurrentMode: Get the current VBE mode number
; -Output-
; ax: system code
; bx: current mode number
; ============================================================
VBEGetCurrentMode:
	mov ax, 0
	call switchMode

	mov ax, 0x4F03
	xor di, di
	int 0x10

	push bx
	push ax

	mov ax, 1
	call switchMode

	pop ax
	pop bx

	jmp checkVBEResult

; ============================================================
; VBEFindMode: Find a VBE mode matching resolution and bpp
; -Input-
; ax: desired width in pixels
; bx: desired height in pixels
; cl: desired bits per pixel (0 = any)
; -Output-
; ax: system code
; bx: mode number (0xFFFF if not found)
; ============================================================
VBEFindMode:
	push bp
	mov bp, sp
	push ax
	push bx
	push cx
	push di
	push ds
	push es

	call VBEGetControllerInfo
	cmp ax, SYSTEM_CODE_SUCCESS
	jne .fail

	mov ax, [VESABuffer + VesaInfoBlock.VideoModesOffset]
	mov bx, [VESABuffer + VesaInfoBlock.VideoModesSegment]
	mov si, ax
	mov ds, bx
	push cs
	pop es

.nextMode:
	lodsw
	cmp ax, 0xFFFF
	je .notFound

	push ax
	push ds
	push si

	push cs
	pop es
	mov di, ModeInfoBuffer
	mov cx, ax
	mov ax, 0x4F01
	int 0x10

	cmp al, 0x4F
	jne .skip

	test word [ModeInfoBuffer + ModeInfoBlock.ModeAttributes], MODE_ATTR_AVAILABLE
	jz .skip

	mov ax, [bp - 2]
	cmp [ModeInfoBuffer + ModeInfoBlock.XResolution], ax
	jne .skip

	mov ax, [bp - 4]
	cmp [ModeInfoBuffer + ModeInfoBlock.YResolution], ax
	jne .skip

	mov cl, [bp - 6]
	cmp cl, 0
	je .found

	cmp [ModeInfoBuffer + ModeInfoBlock.BitsPerPixel], cl
	jne .skip

.found:
	pop si
	pop ds
	pop bx
	pop es
	pop ds
	pop di
	pop cx
	mov [VBETemp], bx
	pop bx
	pop ax
	mov bx, [VBETemp]
	mov ax, SYSTEM_CODE_SUCCESS
	pop bp
	ret

.skip:
	pop si
	pop ds
	pop ax
	jmp .nextMode

.notFound:
.fail:
	mov bx, 0xFFFF
	mov ax, SYSTEM_CODE_ERROR_VBE_INVALID_MODE
	pop es
	pop ds
	pop di
	pop cx
	pop bx
	pop ax
	pop bp
	ret

; ============================================================
; VBESetDisplayStart: Set display start (page flipping)
; -Input-
; cx: first pixel in scan line
; dx: first displayed scan line
; bl: 0 = display start, 1 = during vertical retrace
; -Output-
; ax: system code
; ============================================================
VBESetDisplayStart:
	push cx
	push dx
	push bx

	mov ax, 0
	call switchMode

	pop bx
	pop dx
	pop cx

	mov ax, 0x4F07
	int 0x10

	push ax

	mov ax, 1
	call switchMode

	pop ax

	jmp checkVBEResult

; ============================================================
; VBEGetDisplayStart: Get current display start
; -Output-
; ax: system code
; bx: first pixel in scan line
; cx: first displayed scan line
; ============================================================
VBEGetDisplayStart:
	mov ax, 0
	call switchMode

	mov ax, 0x4F07
	mov bx, 0x0001
	xor cx, cx
	xor dx, dx
	int 0x10

	push cx
	push bx
	push ax

	mov ax, 1
	call switchMode

	pop ax
	pop bx
	pop cx

	jmp checkVBEResult

; ============================================================
; VBESaveRestoreState: Save/restore VBE video state
; VBE 2.0+ function 0x4F04
; -Input-
; bx: subfunction (SR_STATE_SAVE/SR_STATE_RESTORE/SR_STATE_SIZE/SR_STATE_SET)
; cx: state buffer size (for SR_STATE_SET, bits 0-3 = state flags)
; dx: state request flags (bits: 0=hardware, 1=BIOS, 2=DAC, 3=registers)
; es:di: buffer pointer (for SR_STATE_SAVE/SR_STATE_SET)
; -Output-
; ax: system code
; bx: buffer size (for SR_STATE_SIZE)
; ============================================================
VBESaveRestoreState:
	push dx
	push cx
	push bx

	mov ax, 0
	call switchMode

	pop bx
	pop cx
	pop dx

	mov ax, 0x4F04
	int 0x10

	push bx
	push ax

	mov ax, 1
	call switchMode

	pop ax
	pop bx

	jmp checkVBEResult

; ============================================================
; VBESetPaletteData: Set VBE palette entries (VBE 2.0+)
; Function 0x4F08, subfunction 0x01
; -Input-
; bx: number of entries to set
; cx: starting index
; dx: attribute controller index
; es:di: pointer to palette data (entry = [blue, green, red, alignment] x count)
; -Output-
; ax: system code
; ============================================================
VBESetPaletteData:
	push bx
	push cx
	push dx
	push di
	push es

	mov ax, 0
	call switchMode

	pop es
	pop di
	; bx = number of entries, cx = start index, dx = attribute index
	push dx
	push cx
	push bx

	mov ax, 0x4F08
	mov bx, 0x0001
	int 0x10

	push ax

	mov ax, 1
	call switchMode

	pop ax

	call checkVBEResult
	pop cx
	pop cx
	pop dx
	ret

; ============================================================
; VBEGetPaletteData: Get VBE palette entries (VBE 2.0+)
; Function 0x4F08, subfunction 0x00
; -Input-
; bx: number of entries to get
; cx: starting index
; dx: attribute controller index
; es:di: pointer to palette data buffer
; -Output-
; ax: system code
; ============================================================
VBEGetPaletteData:
	push bx
	push cx
	push dx
	push di
	push es

	mov ax, 0
	call switchMode

	pop es
	pop di
	push dx
	push cx
	push bx

	mov ax, 0x4F08
	xor bx, bx
	int 0x10

	push ax

	mov ax, 1
	call switchMode

	pop ax

	call checkVBEResult
	pop cx
	pop cx
	pop dx
	ret

; ============================================================
; VBESetPaletteFormat: Set DAC palette format (VBE 3.0)
; Function 0x4F09, subfunction 0x01
; -Input-
; bl: palette format (6 = 6-bit DAC, 8 = 8-bit DAC)
; -Output-
; ax: system code
; ============================================================
VBESetPaletteFormat:
	push bx

	mov ax, 0
	call switchMode

	pop bx

	mov ax, 0x4F09
	mov bh, 0x01
	int 0x10

	push ax

	mov ax, 1
	call switchMode

	pop ax

	jmp checkVBEResult

; ============================================================
; VBEGetPaletteFormat: Get DAC palette format (VBE 3.0)
; Function 0x4F09, subfunction 0x00
; -Output-
; ax: system code
; bl: current palette format (6 = 6-bit DAC, 8 = 8-bit DAC)
; ============================================================
VBEGetPaletteFormat:
	mov ax, 0
	call switchMode

	mov ax, 0x4F09
	xor bh, bh
	int 0x10

	push bx
	push ax

	mov ax, 1
	call switchMode

	pop ax
	pop bx

	jmp checkVBEResult

; ============================================================
; VBEDPMSGet: Get DPMS capabilities and current state
; VBE 3.0 function 0x4F10, subfunction 0x00
; -Output-
; ax: system code
; bx: DPMS capabilities (bit 0=on, bit 1=standby, bit 2=suspend, bit 3=off)
; cx: current DPMS state (on/standby/suspend/off)
; ============================================================
VBEDPMSGet:
	mov ax, 0
	call switchMode

	mov ax, 0x4F10
	xor bx, bx
	int 0x10

	push cx
	push bx
	push ax

	mov ax, 1
	call switchMode

	pop ax
	pop bx
	pop cx

	jmp checkVBEResult

; ============================================================
; VBEDPMSSet: Set DPMS power state
; VBE 3.0 function 0x4F10, subfunction 0x01
; -Input-
; bl: DPMS state (DPMS_ON/DPMS_STANDBY/DPMS_SUSPEND/DPMS_OFF)
; -Output-
; ax: system code
; ============================================================
VBEDPMSSet:
	push bx

	mov ax, 0
	call switchMode

	pop bx

	mov ax, 0x4F10
	mov bh, 0x01
	int 0x10

	push ax

	mov ax, 1
	call switchMode

	pop ax

	jmp checkVBEResult

; ============================================================
; VBEFlatPanelGet: Get flat panel parameters (VBE 3.0)
; Function 0x4F11, subfunction 0x00
; -Output-
; ax: system code
; bx: flat panel capabilities
; cx: panel X size in pixels
; dx: panel Y size in pixels
; ============================================================
VBEFlatPanelGet:
	mov ax, 0
	call switchMode

	mov ax, 0x4F11
	xor bx, bx
	int 0x10

	push dx
	push cx
	push bx
	push ax

	mov ax, 1
	call switchMode

	pop ax
	pop bx
	pop cx
	pop dx

	jmp checkVBEResult

; ============================================================
; VBEFlatPanelSet: Set flat panel parameters (VBE 3.0)
; Function 0x4F11, subfunction 0x81
; -Input-
; bx: function number (subfunction 0x81 for panel setup)
; Typically: BH=0x81, BL=panel number or 0
; -Output-
; ax: system code
; ============================================================
VBEFlatPanelSet:
	push bx

	mov ax, 0
	call switchMode

	pop bx

	mov ax, 0x4F11
	int 0x10

	push ax

	mov ax, 1
	call switchMode

	pop ax

	jmp checkVBEResult

; ============================================================
; VBEGetEDID: Get EDID data for a given monitor (VBE 3.0+)
; Function 0x4F15, BL=0x01
; -Input-
; cx: EDID block number (0 = first 128-byte block)
; dx: monitor port number (0 = primary)
; es:di: pointer to 128-byte buffer for EDID data
; -Output-
; ax: system code
; ============================================================
VBEGetEDID:
	push di
	push es
	push cx
	push dx

	mov ax, 0
	call switchMode

	pop dx
	pop cx
	pop es
	pop di

	mov ax, 0x4F15
	mov bl, 0x01
	int 0x10

	push ax

	mov ax, 1
	call switchMode

	pop ax

	jmp checkVBEResult

; ============================================================
; VBEGetSetDisplayData: Video mirroring / display data (VBE 3.0)
; Function 0x4F0C
; -Input-
; bh: subfunction (0x00 = get display count, 0x01 = set display data)
; bl: display number (for subfunction 0x01)
; cx: X offset
; dx: Y offset
; si: new display width
; di: new display height
; -Output-
; ax: system code
; bh: number of displays (for subfunction 0x00)
; ============================================================
VBEGetSetDisplayData:
	push di
	push si
	push dx
	push cx
	push bx

	mov ax, 0
	call switchMode

	pop bx
	pop cx
	pop dx
	pop si
	pop di

	mov ax, 0x4F0C
	int 0x10

	push bx
	push ax

	mov ax, 1
	call switchMode

	pop ax
	pop bx

	jmp checkVBEResult

; ============================================================
; VBEStereo: Enable/disable stereo (VBE 3.0)
; Function 0x4F13
; -Input-
; bh: subfunction (0x00 = get stereo mode, 0x01 = set stereo mode)
; bl: stereo mode (for set)
; -Output-
; ax: system code
; bl: stereo mode (for get)
; ============================================================
VBEStereo:
	push bx

	mov ax, 0
	call switchMode

	pop bx

	mov ax, 0x4F13
	int 0x10

	push bx
	push ax

	mov ax, 1
	call switchMode

	pop ax
	pop bx

	jmp checkVBEResult

; ============================================================
; vbeInit: Initialize VBE subsystem and optionally set a mode
; -Input-
; ax: mode number to set (0 = keep current mode)
; -Output-
; ax: system code
; ============================================================
vbeInit:
	push bp
	mov bp, sp
	push ax

	call supportedVersionOfVBE
	cmp ax, 2
	jl .noVBE

	call VBEGetControllerInfo
	cmp ax, SYSTEM_CODE_SUCCESS
	jne .fail

	mov ax, [bp - 2]
	cmp ax, 0
	je .done

	call changeResulation
	pop ax
	pop bp
	ret

.done:
	mov ax, SYSTEM_CODE_SUCCESS
	pop ax
	pop bp
	ret

.noVBE:
	mov ax, SYSTEM_CODE_ERROR_NO_VBE_SUPPORT
	pop ax
	pop bp
	ret

.fail:
	pop ax
	pop bp
	ret

; ============================================================
; Data
; ============================================================

VESABuffer:			times 512 db 0
ModeInfoBuffer:		times 256 db 0
EDIDBuffer:			times EDID_BLOCK_SIZE db 0
RESULATION:			dd 0
VBETemp:			dw 0

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

struc VesaModeInfoBlock				;	VesaModeInfoBlock_size = 256 bytes
	.ModeAttributes		resw 1
	.FirstWindowAttributes	resb 1
	.SecondWindowAttributes	resb 1
	.WindowGranularity	resw 1		;	in KB
	.WindowSize		resw 1		;	in KB
	.FirstWindowSegment	resw 1		;	0 if not supported
	.SecondWindowSegment	resw 1		;	0 if not supported
	.WindowFunctionPtr	resd 1
	.BytesPerScanLine	resw 1

	;	Added in Revision 1.2
	.Width			resw 1		;	in pixels(graphics)/columns(text)
	.Height			resw 1		;	in pixels(graphics)/columns(text)
	.CharWidth		resb 1		;	in pixels
	.CharHeight		resb 1		;	in pixels
	.PlanesCount		resb 1
	.BitsPerPixel		resb 1
	.BanksCount		resb 1
	.MemoryModel		resb 1		;	http://www.ctyme.com/intr/rb-0274.htm#Table82
	.BankSize		resb 1		;	in KB
	.ImagePagesCount	resb 1		;	count - 1
	.Reserved1		resb 1		;	equals 0 in Revision 1.0-2.0, 1 in 3.0

	.RedMaskSize		resb 1
	.RedFieldPosition	resb 1
	.GreenMaskSize		resb 1
	.GreenFieldPosition	resb 1
	.BlueMaskSize		resb 1
	.BlueFieldPosition	resb 1
	.ReservedMaskSize	resb 1
	.ReservedMaskPosition	resb 1
	.DirectColorModeInfo	resb 1

	;	Added in Revision 2.0
	.LFBAddress		resd 1
	.OffscreenMemoryOffset	resd 1
	.OffscreenMemorySize	resw 1		;	in KB
	.Reserved2		resb 206	;	available in Revision 3.0, but useless for now
endstruc

; Usage:
; -Output-
; al = 3: VBE3
; al = 2: VBE2
; al = 0: Unsupported
bits 16
supportedVersionOfVBE:
    mov dword [es:di], 'VBE3'
    mov ax, 0x4F00
    int 0x10
    cmp al, 0x4F
    jne .V2

    mov ax, 3
    ret
.V2:
    mov dword [es:di], 'VBE2'
    mov ax, 0x4F00
    int 0x10
    cmp al, 0x4F
    jne .incap

    mov ax, 2
    ret
.incap:
    mov ax, 0
    ret

; Usage:
; -Input-
; eax: Resulation
changeResulation:
    bits 16
    push ax                 ; save resolution mode number
    call supportedVersionOfVBE
    cmp ax, 3
    je .V3
    cmp ax, 2
    je .V2

    add sp, 2               ; discard saved mode number
    mov ax, SYSTEM_CODE_ERROR_INCAPABLE
    mov bx, RES_CHNG_INCAP
    ret
.V3:
    add sp, 2               ; discard saved mode number
    mov ax, 256
    call kmalloc
    cmp ax, SYSTEM_CODE_SUCCESS
    jne .done

    jmp .done
.V2:
    pop bx                  ; bx = saved resolution mode number
    mov ax, 0
    call switchMode

    mov ax, 0x4F02
    int 0x10

    mov ax, 1
    call switchMode
    jmp .done
.done:
    ret

VESA_INFO_ADDR db 0
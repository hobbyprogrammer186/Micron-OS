;
; Copyright (C) 2026 First Person
;
; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.
;

bits 32
org 0x7E00

%include "gdt.asm"
%include "idt.asm"
%include "paging.asm"
%include "definations.asm"

%ifdef DUMMY_BUILD
%include "dummy/mm.asm"
%include "dummy/vesa.asm"
%endif

start:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ax, 0x7E00
    mov ss, ax

    call gdtInit
    call mmInit
    mov eax, 0x0118
    call changeResulation
    jmp $

; Usage:
; -Input-
; ax: system error code (defiend in definations.asm)
; bx: error message leave empty to set default by error code
panic:
    hlt

; Usage:
; -Input-
; ax: system code (defiend in definations.asm)
; (Error code = Error, Warning code = Warning, Info Code = Info)
; bx: error message leave empty to set default by error code
log:
    ret

; Usage:
; -Input-
; ax: mode (0 for real, 1 for protected)
switchMode:
    cmp ax, 0
    je .real
    jmp .protected
.real:
    cli
    mov ax, 0
    call gdtSetMode
    call disablePaging
    call idtDisable

    mov sp, 0x8000
    mov ax, 0
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    ret
.protected:
    cli
    mov ax, 1
    call gdtSetMode
    call enablePaging
    call idtEnable
    ret

vbeScreen           db 0

%ifdef SIZE
times SIZE-($-$$)   db 0
%endif
kend                db 0    ; End Of Kernel Address
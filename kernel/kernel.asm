bits 32
org 0x7E00

%include "gdt.asm"
%include "idt.asm"
%include "vesa.asm"
%include "definations.asm"

start:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ax, 0x7E00
    mov ss, ax

    call gdtInit
    mov eax, 0x0118
    call changeResulation

switchMode:
    cmp ax, 0
    je .real
    jmp .protected
.real:
    cli
    mov ax, 0
    call gdtSetMode

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
    ret

vbeScreen      db 0
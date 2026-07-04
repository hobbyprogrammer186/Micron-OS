%include "vesa.asm"
%include "definations.asm"

switchMode:

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

changeResulation:
    bits 16
    call supportedVersionOfVBE
    cmp ax, 3
    je .V3
    cmp ax, 2
    je .V2
    
    mov ax, SYSTEM_CODE_ERROR_INCAPABLE
    xor bx, bx
    ret
.V3:

    ret
.V2:
    mov ax, 0
    call switchMode

    ret
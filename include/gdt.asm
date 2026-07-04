;
; Copyright (C) 2026 First Person
;
; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.
;

section .data
gdtTable:
    ; 0x00: Null Descriptor
    dq 0x0

    ; 0x08: Kernel Code Descriptor (DPL=0, Type=0x9A)
    dq 0x00CF9A000000FFFF

    ; 0x10: Kernel Data Descriptor (DPL=0, Type=0x92)
    dq 0x00CF92000000FFFF

    ; 0x18: User Code Descriptor (DPL=3, Type=0xFA)
    dq 0x00CFFA000000FFFF

    ; 0x20: User Data Descriptor (DPL=3, Type=0xF2)
    dq 0x00CFF2000000FFFF
gdtTableEnd:

gdtDescriptor:
    dw gdtTableEnd - gdtTable - 1 ; Limit (size - 1)
    dd gdtTable                   ; Base address

gdtInit:
    lgdt [gdtDescriptor]
    ret

gdtSetMode:
    cmp ax, 1
    jge .enable
    jmp .disable
.enable:
    cli
    ; lgdt [gdtDescriptor]
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    jmp .done
.disable:
    mov eax, cr0
    and eax, 0xFFFFFFFE
    mov cr0, eax
    jmp .done
.done:
    ret

reloadSegments:
    ; Reload Code Segment (0x08 is the offset for the first descriptor)
    jmp 0x08:.reloadCS
.reloadCS:
    ; Reload Data Segments (0x10 is the offset for the second descriptor)
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    ret
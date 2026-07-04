gdtTable:
    dq 0        ; Null Descriptor
    dw 0        ; Kernel Mode Code Segment
    dq 0        ; Kernel Mode Data Segment
    dw 0        ; User Mode Code Segment
    dq 0        ; User Mode Data Segment
    db 0        ; Task State Segment
gdtTableEnd:

gdtDescriptor:
    dw gdtTableEnd - gdtTable
    dd gdtTable

gdtInit:
    cli
    mov eax, gdtTable
    mov [gdtDescriptor + 2], eax
    mov ax, gdtTableEnd - gdtTable
    mov [gdtDescriptor], ax
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
    jmp 0x8:.reloadCS
.reloadCS:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    ret
bits 32

%define MEMREG_START        0x00EFFFFF
%define MEMREG_END          MEMREG_START + 0x00E00000

; 0x00EFFFFF To 0x00E00000 is 4 MB And Can Handle The
; (14 * 1000 * 1000) / 24 = 583333.333333 Entries But Safe Entry Count Is 583333
%define MAX_MEMREG_ENTRIES  583333

struc MemRegion
    .base       resq 1
    .len        resq 1
    .type       resd 1
    .acpiExt    resd 1
endstruc

mmInit:
    xor ebx, ebx
    mov ax, 0
    mov bx, 0
    call switchMode

    ; Call To Extend
    mov eax, 0xE820
    mov ecx, ebx
    mov edx, ebx
    int 0x15
    jc .initFail
.loop:
    cmp bx, MAX_MEMREG_ENTRIES
    jge .done

    mov di, bx
    imul di, 24
    add di, MEMREG_START

    mov eax, 0xE820
    mov edx, 0x534D4150
    mov ecx, 24
    int 0x15

    test ebx, ebx
    jz .done

    jc .initFail
    inc bx
    jmp .loop
.initFail:
    mov ax, 1
    call switchMode
    mov ax, MM_INIT_FAILURE
    mov bx, 0
    call panic
.done:
    mov ax, 1
    call switchMode
    ret

getArrayValue:
setArrayValue:
kmalloc:
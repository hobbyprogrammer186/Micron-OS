bits 32

%include "definations.asm"
%ifdef DUMMY_BUILD
%include "dummy/kernel.asm"
%endif

%define MEMREG_START            0x00EFFFFF
%define MEMREG_END              MEMREG_START + 0x00E00000

; 0x00EFFFFF To 0x00E00000 is 14 MB And Can Handle The
; (14 * 1000 * 1000) / 24 = 583333.333333 Entries But Safe Entry Count Is 583333
%define MAX_MEMREG_ENTRIES      583333

struc MemRegion
    .base       resq 1
    .len        resq 1
    .type       resd 1
    .acpiExt    resd 1
endstruc

struc VariableRegion
    .base       resq 1
    .len        resq 1
    .next       resd 1
endstruc

; Define chunk size for memory fragmentation
%define CHUNK_SIZE 4096

mmInit:
    mov ax, 0
    mov bx, 0
    call switchMode

    xor ebx, ebx
    mov eax, 0xE820
    mov ecx, ebx
    mov edx, ebx
    int 0x15
    jc .initFail

    mov di, MEMREG_START
    xor bx, bx
.loop:
    cmp bx, MAX_MEMREG_ENTRIES
    jge .done

    mov eax, 0xE820
    mov edx, 0x534D4150
    mov ecx, 24
    int 0x15
    cmp ebx, 0
    je .done

    add di, 24
    add bx, 1
    cmp di, MEMREG_END
    jge .bufferOverflow
    jmp .loop
.initFail:
    mov ax, 1
    call switchMode
    mov ax, SYSTEM_CODE_ERROR_MM_INIT_FAILURE
    mov bx, 0
    call panic
.bufferOverflow:
    mov ax, 1
    call switchMode
    mov ax, SYSTEM_CODE_ERROR_BUFFER_OVERFLOW
    mov bx, 0
    call panic
.done:
    mov [endAddressOfMemReg], di
    mov [allocatedMemRegEntries], bx
    mov ax, 1
    call switchMode
    ret

getAddressOfList:
    imul ax, bx
    add cx, ax
    mov ax, cx
    ret

; Usage
; -Input-
; ax: source address (pointer to VariableRegion chain)
; bx: size
; cx: target address
memcpy:
    push ax
    push bx
    push cx
    push si
    push di

    mov si, ax
    mov di, cx
    mov cx, bx

    cmp dword [si + VariableRegion.base], 0
    je .notExist

.getLen:
    mov bx, [si + VariableRegion.len]

.isEnoughForFit:
    cmp cx, bx
    je .checkChunk
    jb .enough

    ; cx > bx: copy full chunk, reduce remaining, follow next
    push cx
    push si
    lea si, [si + VariableRegion_size]
    mov cx, bx
    rep movsb
    pop si
    pop cx
    sub cx, bx

.next:
    mov si, [si + VariableRegion.next]
    cmp si, 0
    je .notEnough
    jmp .getLen

.checkChunk:
    ; cx == bx: copy entire chunk and finish
    push cx
    lea si, [si + VariableRegion_size]
    rep movsb
    pop cx
    jmp .done

.enough:
    ; cx < bx: copy only remaining cx bytes from this chunk
    push cx
    lea si, [si + VariableRegion_size]
    rep movsb
    pop cx
    jmp .done

.notExist:
    pop di
    pop si
    pop cx
    pop bx
    pop ax
    mov ax, SYSTEM_CODE_ERROR_INVALID_MEMORY_BLOCK
    ret

.notEnough:
    pop di
    pop si
    pop cx
    pop ax
    mov ax, SYSTEM_CODE_ERROR_OUT_OF_MEMORY
    xor bx, bx
    call log
    pop bx
    ret

.done:
    pop di
    pop si
    pop cx
    pop ax
    mov ax, SYSTEM_CODE_SUCCESS
    xor bx, bx
    call log
    pop bx
    ret


; Usage:
; -Input-
; ax: byte
; -Output-
; ax: system code (0 = success)
; bx: pointer (only valid when ax = 0 after allocating)
kmalloc:
    cmp ax, 0
    je .ilegalNumber
    pushad
    xor bx, bx                  ; Start Address
    xor ecx, ecx                ; Ofset
    mov edx, MEMREG_START       ; Memory Region Address
.findUseableAddress:
    cmp edx, [endAddressOfMemReg]
    jge .allocationFailed
    cmp dword [edx + MemRegion.type], MREGION_USEABLE
    je .foundUseable
    ;cmp dword [edx + MemRegion.type], MREGION_ACPI_RECL
    ;je .foundUseable
    cmp ecx, [edx + MemRegion.len]
    jge .next

    add ecx, VariableRegion_size
    jmp .findUseableAddress
.next:
    add edx, 24
    xor ecx, ecx
    jmp .findUseableAddress
.foundUseable:
    ; CX: Ofset
    ; AL: Byte Ofset
    cmp ecx, 0
    jne .next
    xor eax, eax                ; Byte Ofset
.isEnoughAddress:
    cmp byte [ecx + eax], 0
    jne .isEnoughAddressEnd

    add al, 1
    jmp .isEnoughAddress
.isEnoughAddressEnd:
    cmp al, VariableRegion_size
    jge .checkAddress
    jmp .notEnough
.notEnough:
    ; Not enough contiguous space at current offset
    ; Move to next offset and continue searching
    add ecx, 1
    jmp .findUseableAddress
.checkAddress:
    ; ECX: Ofset
    ; EDX: Memory Region Address
    push ecx
    push edx
    mov edx, MEMREG_START
    mov ecx, 0
    mov bl, cl      ; Original Ofset
.earlyCheckAddress:
    cmp dword [edx + MemRegion.type], MREGION_USEABLE
    je .checkAddress
    jmp .nextCheck
.checkAddressLoop:
    ; ECX: Ofset
    ; EDX: Memory Region Address
    ; BL: Original Offset
    cmp [endAddressOfMemReg], edx
    je .notUsing

    cmp dword [edx + MemRegion.type], MREGION_ACPI_RECL
    jne .nextCheck

    cmp ecx, [edx + MemRegion.len]
    jge .nextCheck
    cmp [ecx + VariableRegion.base], bl
    je .usingAddress
    add ecx, VariableRegion_size
    jmp .checkAddressLoop
.nextCheck:
    add edx, 24
    jmp .earlyCheckAddress
.usingAddress:
    pop edx
    pop ecx
    add ecx, VariableRegion_size
    jmp .findUseableAddress
.notUsing:
    pop ecx
    pop edx
.startAllocation:
    ; ECX: Offset within memory region
    ; EDX: Memory Region address
    ; AX: Requested size in bytes
    
    ; Save requested size
    push ax
    
    ; Calculate number of chunks needed
    movzx eax, ax
    xor edx, edx
    mov ecx, CHUNK_SIZE
    div ecx
    test edx, edx
    jz .exactChunks
    add eax, 1              ; Round up if remainder
.exactChunks:
    mov esi, eax            ; ESI = number of chunks needed
    
    ; Calculate actual base address: [edx + MemRegion.base] + ecx
    mov ebx, [edx + MemRegion.base]
    add ebx, ecx
    
    ; Save first chunk address to return later
    mov edi, ebx            ; EDI = first chunk address
    
    ; Allocate and link chunks
.allocateLoop:
    test esi, esi
    jz .allocationComplete
    
    ; Store VariableRegion metadata at current chunk
    mov [ebx + VariableRegion.base], ebx
    mov dword [ebx + VariableRegion.len], CHUNK_SIZE
    
    ; If not last chunk, set next to next chunk address
    cmp esi, 1
    je .lastChunk
    lea eax, [ebx + CHUNK_SIZE + VariableRegion_size]
    mov [ebx + VariableRegion.next], eax
    
    ; Move to next chunk position
    add ebx, CHUNK_SIZE
    add ebx, VariableRegion_size
    dec esi
    jmp .allocateLoop
    
.lastChunk:
    ; Last chunk - set next to 0
    mov dword [ebx + VariableRegion.next], 0
    
    ; Calculate actual size for last chunk (may be smaller than CHUNK_SIZE)
    pop ax                  ; Restore requested size
    movzx eax, ax
    mov edx, eax
    xor ecx, ecx
    mov ecx, CHUNK_SIZE
    xor eax, eax
    div ecx
    test edx, edx
    jz .useFullChunk
    mov [ebx + VariableRegion.len], edx
    jmp .allocationComplete
.useFullChunk:
    mov dword [ebx + VariableRegion.len], CHUNK_SIZE
    
.allocationComplete:
    ; Return success with first chunk address in EBX
    mov [tmp], edi
    popad
    mov ax, SYSTEM_CODE_SUCCESS
    push bx
    mov bx, [tmp]
    call log
    pop bx
    ret
    
.allocationFailed:
    ; No suitable memory found
    popad
    mov ax, SYSTEM_CODE_ERROR_OUT_OF_MEMORY
    push bx
    xor bx, bx
    call log
    pop bx
    ret

.ilegalNumber:
    popad
    mov eax, SYSTEM_CODE_ERROR_INVALID_ACCESS_CODE
    xor bx, bx
    call log
    ret

; Usage:
; -Input-
; ax: Chunk Address
; -Output-
; ax: system code (0 = success)
free:
    pushad
    movzx ebx, ax              ; EBX = chunk address
    cmp dword [ebx + VariableRegion.base], 0
    je .notExist
.findChunk:
    ; Clear VariableRegion metadata with loop
    xor eax, eax
    mov ecx, ebx              ; ECX = start of VariableRegion
    mov edx, ebx
    add edx, VariableRegion_size ; EDX = end of VariableRegion
.clearMetadata:
    cmp ecx, edx
    jge .metadataDone
    mov [ecx], eax
    add ecx, VariableRegion_size
    jmp .clearMetadata
.metadataDone:
    ; Clear the actual memory data
    mov ecx, [ebx + VariableRegion.len]
    add ecx, ebx              ; ECX = end address of chunk
    mov edi, ebx              ; EDI = start address
.clearMemory:
    cmp edi, ecx
    jge .nextChunk
    mov byte [edi], 0
    add edi, 1
    jmp .clearMemory
.nextChunk:
    ; Move to next chunk in linked list
    mov ebx, [ebx + VariableRegion.next]
    test ebx, ebx
    jnz .findChunk
    
    ; All chunks deallocated
    mov ax, SYSTEM_CODE_SUCCESS
    popad
    push bx
    xor bx, bx
    call log
    ret
.notExist:
    popad
    mov ax, SYSTEM_CODE_ERROR_INVALID_MEMORY_BLOCK
    push bx
    xor bx, bx
    call log
    pop bx
    ret

allocatedMemRegEntries  db 0
endAddressOfMemReg      dq 0
tmp                     dq 0
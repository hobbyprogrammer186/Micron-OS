; First Stage Bootloader For Floppy Disks
; Do Not Edit Source Code

bits 16
org 0x7C00

%define TEMP_ADDR           0x7D00
%define UPLOAD_ADDR         0x7E00

; FAT32 Defination
%define OEM_Name            "MSWIN4.1"
%define NOT_REMOVEABLE      0xF8
%define REMOVEABLE          0xF0
%define FILENAME            "MICRON     "

start:
    ; Setup The Registers
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    cld

    ; Clear The Screen
    mov ah, 0x00
    mov al, 0x03
    int 0x10

    ; Save Boot Drive
    mov [BOOTDRIVE], dl

    ; Enable A20 Line
    in al, 0x92
    or al, 2
    out 0x92, al

    call uploadBOOTLDR

    ; Jump to kernel at 0x7E00 (16-bit far jump like original)
    jmp 0x0000:UPLOAD_ADDR

    jmp $

DRVERR:
    mov si, DRVERR_MSG
    call print
    jmp $

print:
    mov ah, 0x0E
.loop:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .loop
.done:
    ret

; CHS Read Function
; Input: AX = LBA sector number, BX = buffer address, CX = number of sectors
; Output: CF set on error
readSectorCHS:
    pusha
    mov di, ax          ; Save LBA
    mov si, cx          ; Save sector count
    push bx             ; Save buffer address
    
    ; Convert LBA to CHS
    ; Assume standard floppy: 18 sectors/track, 2 heads
    
    ; Step 1: Compute Temp = LBA / SPT
    mov ax, di
    mov bl, 18
    div bl
    
    ; Step 2: Derive Sector = (LBA % SPT) + 1
    inc ah
    mov cl, ah
    
    ; Step 3: Reload LBA and recompute Temp = LBA / SPT
    mov ax, di
    xor dx, dx
    mov cx, 18
    div cx
    
    ; Step 4: Derive Cylinder = Temp / HPC, Head = Temp % HPC
    mov bl, 2
    div bl
    mov ch, al
    mov dh, ah
    
    ; Step 5: Pack CL = Sector | ((Cylinder >> 2) & 0xC0)
    shr al, 2
    and al, 0xC0
    or cl, al
    
    mov dl, [BOOTDRIVE] ; DL = drive number
    pop bx              ; BX = original buffer address (physical)
    
    xor ax, ax
    mov es, ax          ; ES = 0
    
    mov ax, si          ; AL = number of sectors
    mov ah, 0x02        ; BIOS read function
    
    int 0x13
    popa
    ret

uploadBOOTLDR:
    ; Simplified: read fixed LBA range (78-89, 12 sectors)
    ; This matches the known disk image layout for MICRON file
    mov ax, 78              ; Start LBA sector
    mov cx, 12              ; 12 sectors to read
    mov di, UPLOAD_ADDR     ; Destination buffer
.read_loop:
    ; Read this sector
    mov bx, di              ; Buffer address
    push cx                 ; Save sector count
    mov cx, 0x0001          ; Read 1 sector
    call readSectorCHS
    pop cx                  ; Restore sector count
    jc DRVERR

    ; Advance buffer pointer and LBA
    add di, 512
    inc ax                  ; Next LBA sector
    loop .read_loop
    ret

BUFFER                  equ 0x8000
MBR_SIGN                equ 0x55AA ; MBR Disk Signature
DRVERR_MSG              db "DISK ERR", 0
BOOTDRIVE               dw 0

times 440-($-$$) db 0
dw 0xAA55
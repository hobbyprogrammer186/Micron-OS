; Build complete 1.44MB floppy disk image with MBR partitioning and FAT32.
; Layout:
;   Sector   0 (LBA   0): MBR (512 bytes)
;   Sector   1 (LBA   1): FAT32 VBR + BPB
;   Sector   2 (LBA   2): FSInfo sector
;   Sectors  3-32 (LBA  3-32): Reserved (30 sectors)
;   Sectors 33-54 (LBA 33-54): FAT #1 (22 sectors)
;   Sectors 55-76 (LBA 55-76): FAT #2 (22 sectors, mirror)
;   Sector  77 (LBA  77): Root directory cluster (cluster 2, 1 sector)
;   Sectors 78-89 (LBA 78-89): MICRON file data (clusters 3-14, 12 sectors, 6144 bytes)
;   Sectors 90-2879 (LBA 90-2879): Free space
; Geometry: 80 cylinders, 2 heads, 18 sectors/track = 2880 sectors

section .data

; =============================================================================
; Sector 0: MBR (512 bytes)
; =============================================================================
firstStage:
    incbin "floppyboot.bin", 0, 440      ; Bootstrap code (bytes 0-439)

    dd 0                                  ; Disk ID (bytes 440-443)
    dw 0                                  ; Reserved (bytes 444-445)

                                          ; Partition Entry 1 (bytes 446-461)
    db 0x80                               ; Boot indicator (bootable)
    db 0, 0x01, 0                         ; CHS start: head=0, sector=1, cylinder=0
    db 0x0C                               ; System ID: FAT32 with LBA
    db 1, 0x52, 79                        ; CHS end: head=1, sector=18, cylinder=79
    dd 1                                  ; LBA start (sector 1)
    dd 2879                               ; Total sectors in partition

    times 48 db 0                         ; Partition entries 2-4 (empty)

    dw 0xAA55                             ; MBR signature (bytes 510-511)

; =============================================================================
; FAT32 Partition (LBA 1 through LBA 2879)
; =============================================================================

; ---- LBA 1: FAT32 VBR + BPB (512 bytes) ----
                                          ; Common BPB fields (offsets match bootloader's FAT struct)
    db 0xEB, 0x58, 0x90                   ; BS_BOOTADDR  (0-2): Jump instruction
    db "MSWIN4.1"                         ; BS_OEMName   (3-10): OEM name
    dw 512                                ; BPB_BytsPerSec (11-12)
    db 1                                  ; BPB_SecPerClus (13): 1 sector per cluster
    dw 32                                 ; BPB_RsvdSecCnt (14-15): 32 reserved sectors
    db 2                                  ; BPB_NumFATs  (16): 2 FAT tables
    dw 0                                  ; BPB_RootEntCnt (17-18): 0 for FAT32
    dw 0                                  ; BPB_TotSec16 (19-20): 0 for FAT32
    db 0xF0                               ; BPB_Media    (21): removable
    dw 0                                  ; BPB_FATSz16  (22-23): 0 for FAT32
    dw 18                                 ; BPB_SecPerTrk (24-25)
    dw 2                                  ; BPB_NumHeads (26-27)
    dw 1                                  ; BPB_HiddSec  (28-29): 1 (the MBR sector)
    dd 2879                               ; BPB_TotSec32 (30-33)

    db 0                                  ; Padding (offset 34) to match FAT32.FAT_STRUCTURE (35 bytes)

                                          ; FAT32-specific fields (offset 35+ in bootloader's FAT32 struct)
    dd 22                                 ; BPB_FATSz32  (35-38): 22 sectors per FAT
    dw 0                                  ; BPB_ExtFlags (39-40)
    dw 0                                  ; BPB_FSVer    (41-42)
    dd 2                                  ; BPB_RootClus (43-46): root dir is cluster 2
    dw 1                                  ; BPB_FSInfo   (47-48): FSInfo at sector 2
    dw 0                                  ; BPB_BkBootSec (49-50): no backup
    times 12 db 0                         ; BPB_Reserved (51-62)
    db 0                                  ; BS_DrvNum    (63)
    db 0                                  ; BS_Reserved1 (64)
    db 0x29                               ; BS_BootSig   (65)
    dd 0                                  ; BS_VolID     (66-69)
    db "MICRONOS   "                      ; BS_VolLab    (70-80): volume label, 11 bytes
    db "FAT32   "                         ; BS_FilSysType (81-88): 8 bytes

    times 421 db 0                        ; Bootstrap code + padding to sector end
    dw 0xAA55                             ; VBR signature (bytes 510-511)

; ---- LBA 2: FSInfo sector (512 bytes) ----
    dd 0x41615252                         ; Lead signature "RRaA"
    times 480 db 0
    dd 0x61417272                         ; Another signature "rrAa"
    dd 0xFFFFFFFF                         ; Last free cluster count (unknown)
    dd 0xFFFFFFFF                         ; Next free cluster hint
    times 12 db 0
    dd 0xAA550000                         ; Trail signature

; ---- LBA 3 through LBA 32: Remaining reserved sectors (30 sectors) ----
    times 30 * 512 db 0

; ---- LBA 33 through LBA 54: FAT #1 (22 sectors = 11264 bytes) ----
fat1_start:
    dd 0x0FFFFFF8                         ; FAT[0]: media descriptor (0xF0 with high bits)
    dd 0x0FFFFFFF                         ; FAT[1]: EOC (reserved)
    dd 0x0FFFFFFF                         ; FAT[2]: EOC (root directory cluster)
                                          ; FAT[3..14]: cluster chain for MICRON
    dd 0x00000004                         ; cluster  3 ->  4
    dd 0x00000005                         ; cluster  4 ->  5
    dd 0x00000006                         ; cluster  5 ->  6
    dd 0x00000007                         ; cluster  6 ->  7
    dd 0x00000008                         ; cluster  7 ->  8
    dd 0x00000009                         ; cluster  8 ->  9
    dd 0x0000000A                         ; cluster  9 -> 10
    dd 0x0000000B                         ; cluster 10 -> 11
    dd 0x0000000C                         ; cluster 11 -> 12
    dd 0x0000000D                         ; cluster 12 -> 13
    dd 0x0000000E                         ; cluster 13 -> 14
    dd 0x0FFFFFFF                         ; cluster 14 -> EOC (end of chain)
    times (22 * 512 - ($ - fat1_start)) db 0

; ---- LBA 55 through LBA 76: FAT #2 (22 sectors, mirror of FAT #1) ----
fat2_start:
    dd 0x0FFFFFF8
    dd 0x0FFFFFFF
    dd 0x0FFFFFFF
    dd 0x00000004, 0x00000005, 0x00000006
    dd 0x00000007, 0x00000008, 0x00000009
    dd 0x0000000A, 0x0000000B, 0x0000000C
    dd 0x0000000D, 0x0000000E, 0x0FFFFFFF
    times (22 * 512 - ($ - fat2_start)) db 0

; ---- LBA 77: Root directory (cluster 2, 1 sector = 512 bytes) ----
                                          ; Directory entry for MICRON (32 bytes)
    db "MICRON     "                      ; DIR_Name (11 bytes, space-padded)
    db 0x20                               ; DIR_Attr: archive
    db 0                                  ; DIR_NTRes
    db 0                                  ; DIR_CrtTimeTenth
    dw 0                                  ; DIR_CrtTime
    dw 0                                  ; DIR_CrtDate
    dw 0                                  ; DIR_LastAccessDate
    dw 0                                  ; DIR_FstClusHI (cluster high word)
    dw 0                                  ; DIR_WrtTime
    dw 0                                  ; DIR_WrtDate
    dw 3                                  ; DIR_FstClusLO (cluster low word = 3)
    dd 5787                               ; DIR_FileSize (5787 bytes)

    times (512 - 32) db 0                 ; Remaining entries: end-of-directory marker (0x00)

; ---- LBA 78 through LBA 89: MICRON file data (clusters 3-14, 12 sectors) ----
    incbin "micron"
    times (12 * 512 - 5787) db 0          ; Pad to exactly 12 sectors

; ---- LBA 90 through LBA 2879: Free space (2790 sectors) ----
    times (2790 * 512) db 0

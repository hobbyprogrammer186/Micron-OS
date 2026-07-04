; Raw x86_64 BIOS/DOS error codes with SYSTEM_CODE_ prefix
; These values correspond to legacy BIOS/DOS AH/AL return codes
; for disk, file, and generic BIOS services.

%define SYSTEM_CODE_SUCCESS                    0x00  ; No error
%define SYSTEM_CODE_ERROR_INVALID_FUNCTION     0x01  ; Invalid function
%define SYSTEM_CODE_ERROR_FILE_NOT_FOUND       0x02  ; File not found
%define SYSTEM_CODE_ERROR_PATH_NOT_FOUND       0x03  ; Path not found
%define SYSTEM_CODE_ERROR_TOO_MANY_OPEN_FILES  0x04  ; Too many open files
%define SYSTEM_CODE_ERROR_ACCESS_DENIED        0x05  ; Access denied
%define SYSTEM_CODE_ERROR_INVALID_HANDLE       0x06  ; Invalid handle
%define SYSTEM_CODE_ERROR_MCB_DESTROYED        0x07  ; Memory control blocks destroyed
%define SYSTEM_CODE_ERROR_OUT_OF_MEMORY        0x08  ; Insufficient memory
%define SYSTEM_CODE_ERROR_INVALID_MEMORY_BLOCK 0x09  ; Invalid memory block address
%define SYSTEM_CODE_ERROR_INVALID_ENVIRONMENT  0x0A  ; Invalid environment
%define SYSTEM_CODE_ERROR_BAD_FORMAT           0x0B  ; Bad format
%define SYSTEM_CODE_ERROR_INVALID_ACCESS_CODE  0x0C  ; Invalid access code
%define SYSTEM_CODE_ERROR_DATA_CRC             0x0D  ; Data CRC error
%define SYSTEM_CODE_ERROR_BAD_REQUEST_LENGTH   0x0E  ; Bad request structure length
%define SYSTEM_CODE_ERROR_SEEK                 0x0F  ; Seek error
%define SYSTEM_CODE_ERROR_UNKNOWN_MEDIA_TYPE   0x10  ; Unknown media type
%define SYSTEM_CODE_ERROR_SECTOR_NOT_FOUND     0x11  ; Sector not found
%define SYSTEM_CODE_ERROR_PRINTER_OUT_OF_PAPER 0x12  ; Printer out of paper
%define SYSTEM_CODE_ERROR_WRITE_FAULT          0x13  ; Write fault
%define SYSTEM_CODE_ERROR_READ_FAULT           0x14  ; Read fault
%define SYSTEM_CODE_ERROR_GENERAL_FAILURE      0x15  ; General failure
%define SYSTEM_CODE_ERROR_SHARING_VIOLATION    0x20  ; Sharing violation
%define SYSTEM_CODE_ERROR_LOCK_VIOLATION       0x21  ; Lock violation
%define SYSTEM_CODE_ERROR_INVALID_SEEK         0x22  ; Invalid seek
%define SYSTEM_CODE_ERROR_NOT_DOS_DISK         0x23  ; Not a DOS disk
%define SYSTEM_CODE_ERROR_SECTOR_NOT_FOUND2    0x24  ; Sector not found (retry)
%define SYSTEM_CODE_ERROR_WRITE_PROTECTED      0x25  ; Write protected
%define SYSTEM_CODE_ERROR_UNKNOWN_UNIT         0x26  ; Unknown unit
%define SYSTEM_CODE_ERROR_DRIVE_NOT_READY      0x27  ; Drive not ready
%define SYSTEM_CODE_ERROR_UNKNOWN_COMMAND      0x28  ; Unknown command
%define SYSTEM_CODE_ERROR_DATA_CHECK           0x29  ; Data check
%define SYSTEM_CODE_ERROR_BAD_REQUEST          0x2A  ; Bad request structure length
%define SYSTEM_CODE_ERROR_MEDIA_CHANGED        0x2B  ; Media changed
%define SYSTEM_CODE_ERROR_DEVICE_RESET         0x2C  ; Device reset
%define SYSTEM_CODE_ERROR_VOLUME_UNKNOWN       0x2D  ; Volume unknown
%define SYSTEM_CODE_ERROR_DEVICE_MISSING       0x2E  ; Device missing
%define SYSTEM_CODE_ERROR_SEEK_ON_DEVICE       0x2F  ; Seek on device
%define SYSTEM_CODE_ERROR_NON_SYSTEM_DISK      0x30  ; Non-system disk
%define SYSTEM_CODE_ERROR_INCAPABLE            0x31  ; Not Supported
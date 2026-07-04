;
; Copyright (C) 2026 First Person
;
; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.
;

enablePaging:
    mov cr3, eax
    mov ebx, cr0
    or ebx, 0x80000000
    mov cr0, ebx
%ifdef KERNEL
    popa
%endif
    ret

disablePaging:
    pusha
    mov eax, cr0
    and eax, 0x7fffffff
    mov cr0, eax
    or eax, 0x80000000
    mov cr0, eax
    ret
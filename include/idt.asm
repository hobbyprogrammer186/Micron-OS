;
; Copyright (C) 2026 First Person
;
; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.
;

idtDescriptor:
    dw 0
    dd 0

idtEnable:
    sidt [idtDescriptor]
    ret

idtDisable:
    lidt [idtDescriptor]
    ret
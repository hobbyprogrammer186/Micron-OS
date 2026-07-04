idtDescriptor:
    dw 0
    dd 0

idtInit:
    sidt [idtDescriptor]
    ret
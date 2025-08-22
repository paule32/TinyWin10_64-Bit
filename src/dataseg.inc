entry_rva equ entry - section_start + 0x1000


; --- .data in writeable .text section ---
msg:
    db " Hello Tiny PE32+ (Win10 x64) OK", 10, 0
caption:
    db "Mini-PE", 0
buffer:
    db "0000000000", 0

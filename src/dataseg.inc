entry_rva equ entry - section_start + 0x1000


; --- .data in writeable .text section ---
msg:
    db " Hello Tiny PE32+ (Win10 x64) OK", 10, 0
caption:
    db "Mini-PE", 0
buffer:
    db "0000000000", 0

file_name:
    db "default.prg", 0
file_exists:
    db "file exists.", 0
file_not_exists:
    db "file does not exists.", 0
    
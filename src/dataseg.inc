;---------------------------------------------------
; \file  dataseg.inc
; \note  (c) 2025 by Jens Kallup - paule32
;        all rights reserved.
;
; \desc  Create a tiny MS-Windows 11 64-bit Pro EXE.
;---------------------------------------------------

msg:
    db " Hello Tiny PE32+ (Win10 x64) OK", 10, 0
caption:
    db "Mini-PE", 0
buffer:
    db "0000000000", 0

fmt:            db "Hello %s #%d", 13,10,0
who:            db "world",0
fmt_err:        db "MessageBoxA failed, GetLastError=%lu",13,10,0
msgbox_text:    db "Alles fertig.",0
msgbox_caption: db "Pure NASM PE64",0

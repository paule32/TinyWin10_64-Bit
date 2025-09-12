; -----------------------------------------------------------------------------
; \file  data64.asm
; \note  (c) 2025 by Jens Kallup - paule32
;        all rights reserved.
;
; \desc  Create a tiny MS-Windows 11 64-bit Pro EXE.
; -----------------------------------------------------------------------------
; .data
; -----------------------------------------------------------------------------
    times (DATA_RAW_PTR - ($ - $$)) db 0
data_start:
; -----------------------------------------------------------------------------

errA: db "MessageBoxW failed",0
capA: db "User32",0

msgW: WSTR 'Hello World'
capW: WSTR 'Pure NASM PE-64'

; -----------------------------------------------------------------------------
data_end:
    times (ALIGN_UP($ - $$, FILEALIGN) - ($ - $$)) db 0

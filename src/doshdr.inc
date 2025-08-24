;---------------------------------------------------
; \file  doshdr.inc
; \note  (c) 2025 by Jens Kallup - paule32
;        all rights reserved.
;
; \desc  Create a tiny MS-Windows 11 64-bit Pro EXE.
;---------------------------------------------------

;---------------------------------------------------
; DOS-Header
;---------------------------------------------------
db 'M','Z'                          ; e_magic
times 0x3C-($-$$) db 0
    dd pe_header - $$               ; e_lfanew -> Offset PE Header

times 0x80-($-$$) db 0              ; Stub auffüllen bis 0x80

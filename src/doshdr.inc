;---------------------------------------------------
; DOS-Header
;---------------------------------------------------
db 'M','Z'                          ; e_magic
    times 0x3C-($-$$) db 0
    dd pe_header - $$               ; e_lfanew -> Offset PE Header

times 0x80-($-$$) db 0              ; Stub auffüllen bis 0x80

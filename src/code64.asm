section_text_start:
_start:
    ; Windows x64 ABI: RCX = 1. Parameter
    ; Windows x64 ABI: bei Function-Eintritt ist RSP ≡ 8 (mod 16)
    ; reserve 32 bytes shadow + 8 für Alignment -> 40 (0x28)
    ;call    test_func
    
    ; Zahl zu String konvertieren (rudimentär)
    ; a = 200 + 100
    ;mov     eax, 200
    ;add     eax, 100
    
    ; Konvertiere in String: lade Zahl aus 'a' in RAX
    ;lea     rdi, [rel buffer]      ; Zeiger auf den Puffer
    ;call    IntToStr
    
    ; Windows x64 ABI: RCX,RDX,R8,R9 + 32 Bytes Shadow Space, 16-Byte Align
    sub     rsp, 64               ; Shadow + Alignment headroom

    ; printf("Hello %s #%d\n", "world", 42);
    lea     rcx, [rel fmt]        ; RCX = format
    lea     rdx, [rel who]        ; RDX = "world"
    mov     r8d, 42               ; R8  = 42
    xor     eax, eax              ; AL = 0 (keine XMM-Args bei varargs!)
    mov     rax, IMAGE_BASE + RVA_IDATA(IAT_printf)
    call    qword [rax]

    ; MessageBoxA(NULL, "Done.", "Title", 0);
    xor     ecx, ecx              ; HWND = 0
    lea     rdx, [rel msgbox_text]
    lea     r8,  [rel msgbox_caption]
    xor     r9d, r9d              ; uType = 0
    mov     rax, IMAGE_BASE + RVA_IDATA(IAT_MessageBoxA)
    call    qword [rax]

    ; ExitProcess(0);
    xor     ecx, ecx
    mov     rax, IMAGE_BASE + RVA_IDATA(IAT_ExitProcess)
    call    qword [rax]
    
    
    ; printf(char*)
    FUNC    printf, msg
    FUNC    printf, msg
    FUNC    printf, msg
    FUNC    printf, msg
    FUNC    printf, msg
;    FUNC    printf, msg
;    FUNC    printf, msg
;    FUNC    printf, msg
;    FUNC    printf, msg
;    FUNC    printf, caption
;    FUNC    printf, caption
    
    ;FUNC    printf, msg
    ;FUNC    printf, caption
    ;FUNC    printf, caption
    ;FUNC    printf, caption
    
    ; Ausgabe via MessageBoxA
    ;FUNC MessageBoxA, 0, msg, caption, 1
    ;FUNC MessageBoxA, 0, msg, caption, 2
    ; printf(char*)
    ;lea     rcx,  [rel msg]          ; printf(const char*)
    ;call    qword [rel iat_printf]
    
    call    exit_func
    
    ; (keine Rückkehr - sollte nie erreicht werden)
    ret

test_func:
    ; printf(char*)
    ret
    ;lea     rcx,  [rel msg]          ; printf(const char*)
    ;call    qword [rel iat_printf]
    
    ;lea     rcx,  [rel msg]          ; printf(const char*)
    ;call    qword [rel iat_printf]
    
    ;lea     rcx,  [rel msg]          ; printf(const char*)
    ;call    qword [rel iat_printf]
    ;lea     rcx,  [rel msg]          ; printf(const char*)
    ;call    qword [rel iat_printf]
    ;lea     rcx,  [rel msg]          ; printf(const char*)
    ;call    qword [rel iat_printf]
    ;lea     rcx,  [rel msg]          ; printf(const char*)
    ;call    qword [rel iat_printf]
    ;lea     rcx,  [rel msg]          ; printf(const char*)
    ;call    qword [rel iat_printf]
    ;lea     rcx,  [rel msg]          ; printf(const char*)
    ;call    qword [rel iat_printf]
 l0:
    ;        mov     rcx,  0                 ; hWnd = NULL
    ;        lea     rdx, [rel msg]           ; Text
    ;        lea     r8,  [rel caption]           ; Caption
    ;        mov     r9d,  1                 ; uType = MB_OK
    ;        call qword [rel iat_MessageBoxA]

    FUNC MessageBoxA, 0, msg, caption, 0
    
    ret

exit_func:
    xor     ecx, ecx                ; ExitProcess(0)
    mov     rax, IMAGE_BASE + RVA_IDATA(IAT_ExitProcess)
    call    qword [rax]

    ret

section_text_end:
times (IDATA_RAW_PTR - ($ - $$)) db 0

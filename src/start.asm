%include 'bits64.inc'
%include 'macros.inc'

;---------------------------------------------------
; DOS / PE-Header
;---------------------------------------------------
%include 'doshdr.inc'
%include 'winhdr.inc'

;---------------------------------------------------
; .text Section (RVA 0x1000, Raw 0x200)
;---------------------------------------------------
section_start:
%include 'stdlib.inc'

test_func:
    ; save stack pointer
    push    rbp
    mov     rbp, rsp

    FUNC MessageBoxA, 0, msg, caption, 0
    
    pop     rbp
    ret

exit_func:
    xor     ecx, ecx                ; ExitProcess(0)
    call    qword [rel iat_ExitProcess]

    pop     rbp
    ret

entry:
    ; Windows x64 ABI: RCX = 1. Parameter
    ; Windows x64 ABI: bei Function-Eintritt ist RSP ≡ 8 (mod 16)
    ; reserve 32 bytes shadow + 8 für Alignment -> 40 (0x28)
    sub     rsp, 40
    
    call    test_func
    
    ; Zahl zu String konvertieren (rudimentär)
    ; a = 200 + 100
    mov     eax, 200
    add     eax, 100
    
    ; Konvertiere in String: lade Zahl aus 'a' in RAX
    lea     rdi, [rel buffer]      ; Zeiger auf den Puffer
    call    IntToStr
    
    ; printf(char*)
    FUNC    printf, msg
    
    ; Ausgabe via MessageBoxA
    FUNC MessageBoxA, 0, buffer, caption, 0
    
    ; printf(char*)
    lea     rcx,  [rel msg]          ; printf(const char*)
    call    qword [rel iat_printf]
    
    call    exit_func
    
    ; (keine Rückkehr - sollte nie erreicht werden)
    add     rsp, 40
    ret

%include 'dataseg.inc'
%include 'textend.inc'
%include 'imports.inc'
%include 'fileend.inc'

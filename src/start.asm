;---------------------------------------------------
; \file  start.asm
; \note  (c) 2025 by Jens Kallup - paule32
;        all rights reserved.
;
; \desc  Create a tiny MS-Windows 11 64-bit Pro EXE.
;---------------------------------------------------
%include 'bits64.inc'
%include 'macros.inc'

%include 'locales.deu'       ; user locales

;---------------------------------------------------
; DOS / PE-Header
;---------------------------------------------------
%include 'doshdr.inc'
%include 'winhdr.inc'

;---------------------------------------------------
; .text Section (RVA 0x1000, Raw 0x200)
;---------------------------------------------------
section_start:
;%include 'stdlib.inc'
entry:
    ; Windows x64 ABI: RCX = 1. Parameter
    ; Windows x64 ABI: bei Function-Eintritt ist RSP ≡ 8 (mod 16)
    ; reserve 32 bytes shadow + 8 für Alignment -> 40 (0x28)
    call    test_func
    
    ; Zahl zu String konvertieren (rudimentär)
    ; a = 200 + 100
    ;mov     eax, 200
    ;add     eax, 100
    
    ; Konvertiere in String: lade Zahl aus 'a' in RAX
    ;lea     rdi, [rel buffer]      ; Zeiger auf den Puffer
    ;call    IntToStr
    
    ; printf(char*)
    FUNC    printf, msg
    FUNC    printf, msg
    
    ; Ausgabe via MessageBoxA
    FUNC MessageBoxA, 0, msg, caption, 1
    
    ; printf(char*)
    ;lea     rcx,  [rel msg]          ; printf(const char*)
    ;call    qword [rel iat_printf]
    
    call    exit_func
    
    ; (keine Rückkehr - sollte nie erreicht werden)
    ret

test_func:
    ; save stack pointer
    
    ; printf(char*)
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
    call    qword [rel iat_ExitProcess]

    pop     rbp
    ret

%include 'dataseg.inc'
%include 'textend.inc'
%include 'imports.inc'
%include 'fileend.inc'

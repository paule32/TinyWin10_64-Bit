; -----------------------------------------------------------------------------
; \file  macros.inc
; \note  (c) 2025 by Jens Kallup - paule32
;        all rights reserved.
;
; \desc  Create a tiny MS-Windows 11 64-bit Pro EXE.
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; add win64 abi shadow ...
; -----------------------------------------------------------------------------
%macro AddShadow 0-1
%if %0 == 1
    sub     rsp, %1
%else
    sub     rsp, 32
%endif
%endmacro

; -----------------------------------------------------------------------------
; delete added win64 abi shadow ...
; -----------------------------------------------------------------------------
%macro DelShadow 0-1
%if %0 == 1
    add     rsp, %1
%else
    add     rsp, 32
%endif
%endmacro

; -----------------------------------------------------------------------------
; MAKE_INT <Label>, <Func1>, <Func2>, ...
; -----------------------------------------------------------------------------
%macro MAKE_INT 2-*
%1:
%assign __n %0-1
%rep __n
    dq RVA_IDATA(HN_win32_%2)
    %rotate 1
%endrep
    dq 0
%endmacro

; -----------------------------------------------------------------------------
; MAKE_IAT <Label>, <Func1>, <Func2>, ...
; -----------------------------------------------------------------------------
%macro MAKE_IAT 2-*
iat_win32_%1:
%assign __n %0-1
%rep __n
IAT_win32_%2: dq RVA_IDATA(HN_win32_%2)
    %rotate 1
%endrep
    dq 0
%endmacro

; -----------------------------------------------------------------------------
; HNSTR <Func1>, <Func2>, ...
; -----------------------------------------------------------------------------
%macro HNSTR 1-*
%assign __n %0
%rep __n
HN_win32_%1: dw 0
    db %str(%1), 0
%rotate 1
%endrep
%endmacro

; -----------------------------------------------------------------------------
; MAKE_IMPORT <dir_label>, <mod1>, <mod2>, ...
; erzeugt:
; dir_label:
;   dd RVA_IDATA(INT_<mod>), 0,0, RVA_IDATA(dll_<mod>), RVA_IDATA(iat_<mod>) ...
;   dd 0,0,0,0,0
; dir_label_end:
; -----------------------------------------------------------------------------
%macro MAKE_IMPORT 1-*
%define __DIR %1
%1:
%assign __n %0-1
%rep __n
    dd RVA_IDATA(INT_win32_%2)
    dd 0,0
    dd RVA_IDATA(dll_win32_%2)
    dd RVA_IDATA(iat_win32_%2)
    %rotate 1
%endrep
    dd 0,0,0,0,0
__DIR %+ _end:
%undef __DIR
%endmacro

; -----------------------------------------------------------------------------
; mini helper ...
; -----------------------------------------------------------------------------
%macro WIN64_PROLOG 0
    mov rbp, rsp
    and rsp, -16
    AddShadow 32         ; Shadow Space
%endmacro

%macro CALL_IAT 1        ; CALL_IAT ExitProcess / RegisterClassExW / ...
    mov     rax, IMAGE_BASE + RVA_IDATA(IAT_win32_%1)
    call    [rax]
%endmacro

; -----------------------------------------------------------------------------
; zero register's
; -----------------------------------------------------------------------------
%macro Zero 1
    xor %1, %1
%endmacro

; -----------------------------------------------------------------------------
; UTF-16LE aus ASCII (<=0x7F) schnell schreiben
; -----------------------------------------------------------------------------
%macro WSTR 1
%push
%strlen __n %1
%assign __i 0
%rep __n
    %substr __c %1 __i+1,1
    dw __c
    %assign __i __i+1
%endrep
    dw 0
%pop
%endmacro

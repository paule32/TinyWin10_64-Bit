;---------------------------------------------------
; \file  asmacro.inc
; \note  (c) 2025 by Jens Kallup - paule32
;        all rights reserved.
;
; \desc  Create a tiny MS-Windows 11 64-bit Pro EXE.
;---------------------------------------------------
%macro FUNC_ENTER 0
    push    rbp
    mov     rbp, rsp
%endmacro

%macro FUNC_LEAVE 0
    pop     rbp
    ret
%endmacro

%macro GET 2
    lea %1, [rel %2]
%endmacro

%macro RELCALL 1
    call qword [rel iat_%+%1]
%endmacro

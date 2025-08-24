;---------------------------------------------------
; \file  winfunc.inc
; \note  (c) 2025 by Jens Kallup - paule32
;        all rights reserved.
;
; \desc  Create a tiny MS-Windows 11 64-bit Pro EXE.
;---------------------------------------------------
%macro FUNC 1-*
    %ifidn %1, ExitProcess
        %if %0 < 2
            %error _error_0001
        %elif %0 > 2
            %error _error_0002
        %else
        ; ExitProcess(exitcode)
            mov     rcx, %2
            RELCALL ExitProcess
        %endif
        
    %elifidn %1, MessageBoxA
        %if %0 < 5
            %error _error_0001
        %elif %0 > 5
            %error _error_0002
        %else
        ; MessageBoxA(hwnd, msg, title, MB_OK)
            mov     rcx, %2                 ; hWnd = NULL
            lea     rdx, [rel %3]           ; Text
            lea     r8,  [rel %4]           ; Caption
            mov     r9,  %5                 ; uType = MB_OK
            RELCALL %1
        %endif
        
    %elifidn %1, printf
    ; printf(const char*)
        lea     rcx,  [rel %2]
        RELCALL %1
    %else
        %error Unknown Function: %1
    %endif
%endmacro

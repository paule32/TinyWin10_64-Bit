; -----------------------------------------------------------------------------
; \file  usefunc.inc
; \note  (c) 2025 by Jens Kallup - paule32
;        all rights reserved.
;
; \desc  Create a tiny MS-Windows 11 64-bit Pro EXE.
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; user32.dll functions ...
; -----------------------------------------------------------------------------
%define USER32_FUNCS \
    RegisterClassExW, CreateWindowExW, DefWindowProcW, \
    ShowWindow, UpdateWindow, GetMessageW, TranslateMessage, \
    DispatchMessageW, PostQuitMessage, LoadCursorW, \
    MessageBoxA, MessageBoxW, GetSysColorBrush, \
    GetClassLongPtrW, GetClientRect, FillRect
; -----------------------------------------------------------------------------
; kernel32.dll functions ...
; -----------------------------------------------------------------------------
%define KERNEL32_FUNCS \
    ExitProcess, \
    GetModuleHandleW, \
    GetLastError

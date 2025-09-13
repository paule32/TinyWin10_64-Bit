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
%define USER32_FUNCS        \
    CreateWindowExW,        \
                            \
    DefWindowProcW,         \
    DispatchMessageW,       \
                            \
    FillRect,               \
                            \
    GetClassLongPtrW,       \
    GetClientRect,          \
    GetMessageW,            \
    GetSysColorBrush,       \
                            \
    LoadCursorW,            \
                            \
    MessageBoxA,            \
    MessageBoxW,            \
                            \
    RegisterClassExW,       \
                            \
    ShowWindow,             \
                            \
    PostQuitMessage,        \
                            \
    TranslateMessage,       \
                            \
    UpdateWindow
    
; -----------------------------------------------------------------------------
; kernel32.dll functions ...
; -----------------------------------------------------------------------------
%define KERNEL32_FUNCS      \
    ExitProcess,            \
                            \
    GetLastError,           \
    GetModuleHandleW,       \
    GetProcAddress,         \
                            \
    LoadLibraryA
    
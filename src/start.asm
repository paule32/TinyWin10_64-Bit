; -----------------------------------------------------------------------------
; \file  start.asm
; \note  (c) 2025 by Jens Kallup - paule32
;        all rights reserved.
;
; \desc  Create a tiny MS-Windows 11 64-bit Pro EXE.
; -----------------------------------------------------------------------------
%include 'basexx.inc'
%include 'windows.inc'
%include 'winfunc.inc'

; -----------------------------------------------------------------------------
; DOS-Header (minimal)
; -----------------------------------------------------------------------------
%include 'doshdr.inc'
%include 'winhdr.inc'
%include 'macros.inc'

; -----------------------------------------------------------------------------
; .text (Code)
; -----------------------------------------------------------------------------
    times (TEXT_RAW_PTR - ($ - $$)) db 0
section_text_start:

; LRESULT CALLBACK WndProc(HWND, UINT, WPARAM, LPARAM)
WndProc:
    ; Prolog für sicheren Call von APIs (Shadow Space)
    sub     rsp, 32
    ; rcx = hWnd, edx = uMsg, r8 = wParam, r9 = lParam
    MESSAGE WM_CLOSE     , wm_close
    MESSAGE WM_ERASEBKGND, wm_erasebkgnd
    
    ; DefWindowProcW(hWnd,uMsg,wParam,lParam)
    DefWindowProcW
    add     rsp, 32
    jmp     [rax]

.wm_erasebkgnd:
    ; rcx=hWnd, r8=HDC
    sub     rsp, 48
    mov     [rsp+32], rcx
    mov     [rsp+40], r8
    lea     rdx, [rsp+16]         ; &RECT
    mov     rcx, [rsp+32]
    CALL_IAT win32_GetClientRect
    
    mov     rcx, [rsp+32]
    mov     rdx, GCLP_HBRBACKGROUND
    CALL_IAT win32_GetClassLongPtrW     ; rax = HBRUSH
    
    mov     rcx, [rsp+40]         ; HDC
    lea     rdx, [rsp+16]         ; &RECT
    mov     r8,  rax              ; HBRUSH
    CALL_IAT win32_FillRect
    
    mov     eax, 1                ; true flag => paint ok.
    add     rsp, 48
    add     rsp, 32
    ret

.wm_close:
    xor     ecx, ecx              ; nExitCode = 0
    CALL_IAT win32_PostQuitMessage
    
    add     rsp, 32
    xor     eax, eax              ; return 0
    ret

_start:
    ; "WinMainCRTStartup"-ähnlich (kein CRT): init + Message-Loop
    ; Wir nehmen lokale Puffer auf dem Stack:
    ;  - WNDCLASSEXW (80 Bytes)
    ;  - MSG (48 Bytes)
    ;  + Shadow Space (32)
    mov     rbp, rsp
    and     rsp, -16
    sub     rsp, 32

    ShowMessageW msgW, capW
    GETLASTERROR jnz, .ok
    
    ; ---- Fallback: Fehlercode anzeigen (MessageBoxA) ----
    GetLastError
    ShowMessageA errA, capW
    
.ok:
    ; vorher: WIN64_PROLOG (richtet aus, reserviert 32 Bytes Shadow Space)
    ; jetzt: zusätzlich Platz für WNDCLASSEXW (80) + MSG (48) + Puffer (16)
    sub     rsp, 80 + 48 + 16
    lea     rdi, [rsp + 16]      ; rdi -> WNDCLASSEXW
    lea     rsi, [rdi + 80]      ; rsi -> MSG
    
    ; hInstance = GetModuleHandleW(NULL)
    xor     ecx, ecx
    CALL_IAT win32_GetModuleHandleW
    mov     r12, rax              ; hInstance in r12 behalten

    ; hCursor = LoadCursorW(NULL, IDC_ARROW)
    LoadCursorW IDC_ARROW
    mov     r14, rax

    ; hbrBackground = GetSysColorBrush(COLOR_WINDOW)
    mov     ecx, 5                    ; COLOR_WINDOW
    CALL_IAT win32_GetSysColorBrush
    mov [rdi+48], rax
    
    ; WNDCLASSEXW füllen (80 Bytes)
    xor     rax, rax
    mov     dword [rdi+0],  80        ; cbSize (lower dword reicht, aber ok)
    mov     dword [rdi+4],  0         ; style
    lea     rax, [rel WndProc]
    mov     [rdi+8], rax              ; lpfnWndProc
    mov     dword [rdi+16], 0         ; cbClsExtra
    mov     dword [rdi+20], 0         ; cbWndExtra
    mov     qword [rdi+24], r12       ; hInstance
    mov     qword [rdi+32], 0         ; hIcon
    mov     qword [rdi+40], r14       ; hCursor
    mov     qword [rdi+48], r15       ; hbrBackground
    mov     qword [rdi+56], 0         ; lpszMenuName
    lea     rax,  [rel winclassW]
    mov     qword [rdi+64], rax       ; lpszClassName
    mov     qword [rdi+72], 0         ; hIconSm

    ; RegisterClassExW(&wc)
    mov     rcx, rdi
    CALL_IAT win32_RegisterClassExW
    GETLASTERROR jnz, .class_ok
    
    ; Fallback: kleine Meldung und Exit
    ShowMessageW  errmsgW, titleW

    sub     rsp, 40
    jmp     .exit

.class_ok:
    ; CreateWindowExW(0, class, title, WS_OVERLAPPEDWINDOW, CW_USEDEFAULT,...)
    xor     ecx, ecx                           ; dwExStyle = 0
    lea     rdx, [rel winclassW]               ; lpClassName
    lea     r8,  [rel titleW]                  ; lpWindowName
    mov     r9d, WS_OVERLAPPEDWINDOW           ; dwStyle

    mov     dword [rsp+32], CW_USEDEFAULT      ; x
    mov     dword [rsp+40], CW_USEDEFAULT      ; y
    mov     dword [rsp+48], 800                ; nWidth
    mov     dword [rsp+56], 600                ; nHeight
    mov     qword [rsp+64], 0                  ; hWndParent
    mov     qword [rsp+72], 0                  ; hMenu
    mov     qword [rsp+80], r12                ; hInstance
    mov     qword [rsp+88], 0                  ; lpParam

    CALL_IAT win32_CreateWindowExW
    GETLASTERROR jz, .exit

    mov     r13, rax                           ; hWnd

    ; ShowWindow(hWnd, SW_SHOWDEFAULT) & UpdateWindow(hWnd)
    ShowWindow   r13, SW_SHOWDEFAULT
    UpdateWindow r13

.msg_loop:
    GetMessageW
    GETLASTERROR jle, .exit
    
    TranslateMessage
    DispatchMessageW
    jmp     .msg_loop

.exit:
    ExitProcess 0

; -----------------------------------------------------------------------------
; konstante Wide-Strings in .text (read-only)
; -----------------------------------------------------------------------------
winclassW:  WSTR "NasmWndClass"
titleW:     WSTR "NASM PE64 GUI without Linker"
errmsgW:    WSTR "RegisterClassExW failed"

section_text_end:

%include 'imports.asm'
%include 'data64.asm'

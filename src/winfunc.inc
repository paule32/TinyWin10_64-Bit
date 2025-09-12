; -----------------------------------------------------------------------------
; \file  winfunc.inc
; \note  (c) 2025 by Jens Kallup - paule32
;        all rights reserved.
;
; \desc  Create a tiny MS-Windows 11 64-bit Pro EXE.
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
%macro DefWindowProcW 0
    mov     rax, IMAGE_BASE + RVA_IDATA(IAT_win32_DefWindowProcW)
%endmacro

; -----------------------------------------------------------------------------
    
; -----------------------------------------------------------------------------
; \brief  DispatchMessageW
; \since  1.0
; -----------------------------------------------------------------------------
%macro DispatchMessageW 0
    mov     rcx, rsi
    CALL_IAT DispatchMessageW
%endmacro

; -----------------------------------------------------------------------------
; \brief  ExitProcess terminate the given application thread.
; \since  1.0
; \param  exitcode -> integer
; \return exitcode -> rax
; -----------------------------------------------------------------------------
%macro ExitProcess 0-1 0
    nop
    AddShadow (32 + 16)           ; Shadow Space + 16B Align
    mov     ecx,%1
    CALL_IAT ExitProcess
    ; no return
    DelShadow (32 + 16)
%endmacro

; -----------------------------------------------------------------------------
; \brief  GetLastError catches the last error that was occured during win32api
;         function call.
; \since  1.0
; \param  nothing
; \return ?
; -----------------------------------------------------------------------------
%macro GETLASTERROR 2
    test    eax, eax
    %1      %2
%endmacro
%macro GetLastError 0
    CALL_IAT GetLastError
%endmacro

; -----------------------------------------------------------------------------
; \brief  GetMessageW
; -----------------------------------------------------------------------------
%macro GetMessageW 0
    mov  rcx, rsi
    Zero edx
    Zero r8d
    Zero r9d
    CALL_IAT GetMessageW
%endmacro

; -----------------------------------------------------------------------------
; \brief  LoadCursorW
; \since  1.0
; \param  id - integer: resource id
; -----------------------------------------------------------------------------
%macro LoadCursorW 1
    Zero ecx
    mov  edx, %1
    CALL_IAT LoadCursorW
%endmacro

; -----------------------------------------------------------------------------
; \brief  MESSAGE is a style shortner for better read expierences ...
; -----------------------------------------------------------------------------
%macro MESSAGE 2
    cmp     edx, %1
    je      .%2
%endmacro

; -----------------------------------------------------------------------------
; \brief ShowMessageW display a wide string message on the desktop screen per
;        the wn32api.
; \since 1.0
; \see   ShowMessageA
;
; \param text_str  -> landet in rdx
; \param title_str -> landet in r8
;
; \param mb_flags  -> optional ( r9d ), default: 0 (MB_OK)
; -----------------------------------------------------------------------------
%macro ShowMessageW 2-3
    Zero    ecx                                 ; hWnd = NULL
    mov     rdx, (IMAGE_BASE + RVA_DATA(%1))    ; lpText
    mov     r8,  (IMAGE_BASE + RVA_DATA(%2))    ; lpCaption    
%if %0 == 2                                     ; %0 = argument count
    xor     r9d, r9d                            ; uType = MB_OK
%else
    mov     r9d, %3                             ; uType = argument exists
%endif
    CALL_IAT MessageBoxW
%endmacro

; -----------------------------------------------------------------------------
; \brief ShowMessageA display a ansi string message on the desktop screen per
;        the wn32api.
; \since 1.0
; \see   ShowMessageW
;
; \param text_str  -> landet in rdx
; \param title_str -> landet in r8
;
; \param mb_flags  -> optional ( r9d ), default: 0 (MB_OK)
; -----------------------------------------------------------------------------
%macro ShowMessageA 2-3
    Zero    ecx
    mov     rdx, IMAGE_BASE + RVA_DATA(%1)      ; "MessageBoxW failed"
    mov     r8,  IMAGE_BASE + RVA_DATA(%2)      ; "User32"
%if %0 == 2                                     ; %0 = argument count
    xor     r9d, r9d                            ; uType = MB_OK
%else
    mov     r9d, %3                             ; uType = argument exists
%endif
    CALL_IAT MessageBoxA
%endmacro

; -----------------------------------------------------------------------------
; \brief  ShowWindow shows the window witht the hwnd id in r13.
; \since  1.0
; \param  hwnd -> HWND handle window
; \param  (optional) flag -> integer: default = SW_SHOWDEFAULT
; -----------------------------------------------------------------------------
%macro ShowWindow 1-2
    nop
    AddShadow (32 + 16)           ; Shadow Space + 16B Align
    mov     rcx, %1
%if %0 == 2
    mov     edx, %2
%else
    mov     edx, SW_SHOWDEFAULT
%endif
    CALL_IAT ShowWindow
    DelShadow (32 + 16)
%endmacro

; -----------------------------------------------------------------------------
; \brief  TranslateMessage
; \since  1.0
; -----------------------------------------------------------------------------
%macro TranslateMessage 0
    mov     rcx, rsi
    CALL_IAT TranslateMessage
%endmacro

; -----------------------------------------------------------------------------
; \brief  UpdateWindow refresh the window properties and draw.
; \since  1.0
;
; \see    Invalidate
; \see    Repaint
;
; \param  hwnd -> HWND handle of window to update
; -----------------------------------------------------------------------------
%macro UpdateWindow 1
    mov     rcx, %1
    CALL_IAT UpdateWindow
%endmacro

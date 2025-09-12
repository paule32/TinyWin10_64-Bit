; -----------------------------------------------------------------------------
; \file  winproc.asm
; \note  (c) 2025 by Jens Kallup - paule32
;        all rights reserved.
;
; \desc  Create a tiny MS-Windows 11 64-bit Pro EXE.
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; LRESULT CALLBACK WndProc(HWND, UINT, WPARAM, LPARAM)
; -----------------------------------------------------------------------------
WndProc:
    ; Prolog für sicheren Call von APIs (Shadow Space)
    AddShadow
    
    ; rcx = hWnd, edx = uMsg, r8 = wParam, r9 = lParam
    MESSAGE WM_CLOSE     , wm_close
    MESSAGE WM_ERASEBKGND, wm_erasebkgnd
    
    ; DefWindowProcW(hWnd,uMsg,wParam,lParam)
    DefWindowProcW
    DelShadow
    
    jmp     [rax]
; -----------------------------------------------------------------------------

.wm_erasebkgnd:
    ; rcx=hWnd, r8=HDC
    AddShadow 48
    mov     [rsp+32], rcx
    mov     [rsp+40], r8
    lea     rdx, [rsp+16]         ; &RECT
    mov     rcx, [rsp+32]
    CALL_IAT GetClientRect
    
    mov     rcx, [rsp+32]
    mov     rdx, GCLP_HBRBACKGROUND
    CALL_IAT GetClassLongPtrW     ; rax = HBRUSH
    
    mov     rcx, [rsp+40]         ; HDC
    lea     rdx, [rsp+16]         ; &RECT
    mov     r8,  rax              ; HBRUSH
    CALL_IAT FillRect
    
    mov     eax, 1                ; true flag => paint ok.
    
    DelShadow 48
    DelShadow
    ret
    
; -----------------------------------------------------------------------------
.wm_close:
    Zero ecx                      ; nExitCode = 0
    CALL_IAT PostQuitMessage
    
    DelShadow
    Zero eax                      ; return 0
    ret

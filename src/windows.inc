; -----------------------------------------------------------------------------
; \file  windows.inc
; \note  (c) 2025 by Jens Kallup - paule32
;        all rights reserved.
;
; \desc  Create a tiny MS-Windows 11 64-bit Pro EXE.
; -----------------------------------------------------------------------------
; win32 constants
; -----------------------------------------------------------------------------
%define WS_OVERLAPPEDWINDOW 0x00CF0000
%define CW_USEDEFAULT       0x80000000
%define SW_SHOWDEFAULT      10

%define IDC_ARROW           32512

%define COLOR_WINDOW        5

; -----------------------------------------------------------------------------
; Window Messages ...
; -----------------------------------------------------------------------------
%define WM_CLOSE            0x0010
%define WM_COMMAND          0x0111
%define WM_ERASEBKGND       0x0014

%define GCLP_HBRBACKGROUND  -10

; -----------------------------------------------------------------------------
; Message Box's ...
; -----------------------------------------------------------------------------
%define MB_OK         0x00000000
%define MB_ICONERROR  0x00000010

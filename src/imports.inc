;---------------------------------------------------
; \file  imports.inc
; \note  (c) 2025 by Jens Kallup - paule32
;        all rights reserved.
;
; \desc  Create a tiny MS-Windows 11 64-bit Pro EXE.
;---------------------------------------------------

; Import-Tabelle --- Hint/Names ---
HINTNAME printf, ExitProcess, MessageBoxA, GetFileAttributesA, GetStdHandle, WriteConsoleA

; --- INTs (Import Name Table, 64-bit Thunks) ---
INT_TABLE msvcrt, printf
INT_TABLE user32, MessageBoxA
INT_TABLE kernel32, ExitProcess, GetFileAttributesA, GetStdHandle, WriteConsoleA

; --- IATs (werden vom Loader gepatcht) ---
IAT_TABLE msvcrt, printf
IAT_TABLE user32, MessageBoxA
IAT_TABLE kernel32, ExitProcess, GetFileAttributesA, GetStdHandle, WriteConsoleA

; --- DLL-Namen ---
IMPORT_DLL msvcrt
IMPORT_DLL user32
IMPORT_DLL kernel32

;align 8
IMPORT_DESC msvcrt
IMPORT_DESC user32
IMPORT_DESC kernel32

; Null-Descriptor
times 20 db 0

;---------------------------------------------------
; \file  imports.inc
; \note  (c) 2025 by Jens Kallup - paule32
;        all rights reserved.
;
; \desc  Create a tiny MS-Windows 11 64-bit Pro EXE.
;---------------------------------------------------

; Import-Tabelle --- Hint/Names ---
;HINTNAME printf, ExitProcess, MessageBoxA, GetFileAttributesA, GetStdHandle, WriteConsoleA

; --- INTs (Import Name Table, 64-bit Thunks) ---
;INT_TABLE msvcrt, printf
;INT_TABLE user32, MessageBoxA
;INT_TABLE kernel32, ExitProcess, GetFileAttributesA, GetStdHandle, WriteConsoleA

; --- IATs (werden vom Loader gepatcht) ---
;IAT_TABLE msvcrt, printf
;IAT_TABLE user32, MessageBoxA
;IAT_TABLE kernel32, ExitProcess, GetFileAttributesA, GetStdHandle, WriteConsoleA

; --- DLL-Namen ---
;IMPORT_DLL msvcrt
;IMPORT_DLL user32
;IMPORT_DLL kernel32

;align 8
;IMPORT_DESC msvcrt
;IMPORT_DESC user32
;IMPORT_DESC kernel32

; Null-Descriptor
;times 20 db 0

; --- Import Directory mit drei Deskriptoren + Terminator
idata_start:
import_dir:
; KERNEL32.DLL
        dd RVA_IDATA(INT_K32)          ; OriginalFirstThunk
        dd 0
        dd 0
        dd RVA_IDATA(dll_kernel32)     ; Name
        dd RVA_IDATA(iat_k32)          ; FirstThunk

; USER32.DLL
        dd RVA_IDATA(INT_USER32)
        dd 0
        dd 0
        dd RVA_IDATA(dll_user32)
        dd RVA_IDATA(iat_user32)

; MSVCRT.DLL
        dd RVA_IDATA(INT_MSVCRT)
        dd 0
        dd 0
        dd RVA_IDATA(dll_msvcrt)
        dd RVA_IDATA(iat_msvcrt)

; Terminator
        dd 0,0,0,0,0
import_dir_end:

; --- INTs (Import Name Tables)
INT_K32:
        dq RVA_IDATA(HN_ExitProcess)
        dq RVA_IDATA(HN_GetLastError)
        dq 0

INT_USER32:
        dq RVA_IDATA(HN_MessageBoxA)
        dq 0

INT_MSVCRT:
        dq RVA_IDATA(HN_printf)
        dq 0

; --- IATs (Import Address Tables) – initial identisch zu INTs
iat_start:

iat_k32:
IAT_ExitProcess:    dq RVA_IDATA(HN_ExitProcess)
IAT_GetLastError:   dq RVA_IDATA(HN_GetLastError)
                    dq 0

iat_user32:
IAT_MessageBoxA: dq RVA_IDATA(HN_MessageBoxA)
                 dq 0

iat_msvcrt:
IAT_printf:      dq RVA_IDATA(HN_printf)
                 dq 0

iat_end:

; --- Hint/Name-Einträge
HN_ExitProcess:     dw 0
                    db 'ExitProcess',0

HN_GetLastError:    dw 0
                    db 'GetLastError',0
                    
HN_MessageBoxA:     dw 0
                    db 'MessageBoxA',0

HN_printf:          dw 0
                    db 'printf',0

; --- DLL-Namen
dll_kernel32:     db 'KERNEL32.DLL',0
dll_user32:       db 'USER32.DLL',0
dll_msvcrt:       db 'MSVCRT.DLL',0

%include 'dataseg.inc'

idata_end:

; Optional auf FileAlignment runden
        times (ALIGN_UP($ - $$, FILEALIGN) - ($ - $$)) db 0

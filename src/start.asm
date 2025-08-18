; tiny64.asm – Minimal PE32+ (x64) für Windows 10+
; erzeugt: 0x400 Byte lauffähige EXE

bits 64
default rel
org 0

%define IMAGEBASE    0x0000000000400000
%define FILEALIGN    0x200
%define SECTALIGN    0x1000

;---------------------------------------------------
; DOS-Header
;---------------------------------------------------
db 'M','Z'                          ; e_magic
times 0x3C-($-$$) db 0
    dd pe_header - $$               ; e_lfanew -> Offset PE Header

times 0x80-($-$$) db 0              ; Stub auffüllen bis 0x80

;---------------------------------------------------
; NT-Header
;---------------------------------------------------
pe_header:
    db 'P','E',0,0                      ; Signature

    ; File Header
    dw 0x8664                           ; Machine = AMD64
    dw 1                                ; NumberOfSections
    dd 0                                ; TimeDateStamp
    dd 0,0                              ; PointerToSymbolTable, NumberOfSymbols
    dw 0xF0                             ; SizeOfOptionalHeader
    dw 0x022                            ; Characteristics (EXECUTABLE|LAA)

    ; Optional Header (PE32+)
    dw 0x20B                            ; Magic = PE32+
    db 0,0                              ; LinkerVersion
    dd 0x200                            ; SizeOfCode
    dd 0,0                              ; SizeOfInit/UninitData
    dd entry_rva                        ; AddressOfEntryPoint
    dd 0x1000                           ; BaseOfCode
    dq IMAGEBASE                        ; ImageBase
    dd SECTALIGN                        ; SectionAlignment
    dd FILEALIGN                        ; FileAlignment
    dw 4,0                              ; OS Version
    dw 0,0                              ; Image Version
    dw 4,0                              ; Subsystem Version
    dd 0                                ; Win32VersionValue
    dd 0x2000                           ; SizeOfImage (Header + 1 Section)
    dd 0x200                            ; SizeOfHeaders
    dd 0                                ; CheckSum
    dw 3                                ; Subsystem = CUI
    dw 0                                ; DllCharacteristics
    dq 0x100000                         ; SizeOfStackReserve
    dq 0x1000                           ; SizeOfStackCommit
    dq 0x100000                         ; SizeOfHeapReserve
    dq 0x1000                           ; SizeOfHeapCommit
    dd 0                                ; LoaderFlags
    dd 16                               ; NumberOfRvaAndSizes

    ; Data Directories
    dd 0,0                              ; Export
    dd import_rva, import_size           ; Import
    times 14*8 db 0                      ; Rest leer

    ; Section Header (.text)
    db '.text',0,0,0                     ; Name
    dd 0x200                             ; VirtualSize
    dd 0x1000                            ; VirtualAddress
    dd 0x200                             ; SizeOfRawData
    dd 0x200                             ; PointerToRawData
    dd 0,0                               ; Reloc/Linenum
    dw 0,0
    dd 0x60000020                        ; Characteristics: CODE|EXEC|READ

;---------------------------------------------------
; Align bis zum Section-Start (0x200)
;---------------------------------------------------
times 0x200-($-$$) db 0

;---------------------------------------------------
; .text Section (RVA 0x1000, Raw 0x200)
;---------------------------------------------------
section_start:

entry:
    ; Windows x64 ABI: RCX = 1. Parameter
    sub     rsp, 40                  ; shadow space + align (32 + 8)
    
    ; MessageBoxA(NULL, msg, title, MB_OK)
    xor     rcx, rcx                 ; hWnd = NULL
    lea     rdx, [rel msg]           ; Text
    lea     r8,  [rel title]         ; Caption
    mov     r9d, 0                   ; uType = MB_OK
    call    qword [rel iat_messagebox]
    
    ; printf(char*)
    lea     rcx,  [rel msg]          ; printf(const char*)
    call    qword [rel iat_printf]
    add     rsp, 40
    
    xor     ecx, ecx                ; ExitProcess(0)
    call    qword [rel iat_exitprocess]
    
    ; (keine Rückkehr)
    ret

entry_rva equ entry - section_start + 0x1000

; Message
msg   db " Hello Tiny PE32+ (Win10 x64) OK", 10, 0
title db "Mini-PE", 0

; Import-Tabelle --- Hint/Names ---
align 8
hintname_printf:
    dw 0
    db 'printf', 0, 0
align 8
hintname_messagebox:
    dw 0
    db 'MessageBoxA', 0, 0
align 8
hintname_exitprocess:
    dw 0
    db 'ExitProcess', 0, 0

; --- INTs (Import Name Table, 64-bit Thunks) ---
align 8
int_msvcrt:
    dq hintname_printf - section_start + 0x1000
    dq 0
; ---
align 8
int_user32:
    dq hintname_messagebox - section_start + 0x1000
    dq 0
; ---
align 8
int_kernel32:
    dq hintname_exitprocess - section_start + 0x1000
    dq 0

; --- IATs (werden vom Loader gepatcht) ---    
iat_msvcrt:
iat_printf:
    dq hintname_printf - section_start + 0x1000
    dq 0
; ---
align 8
iat_user32:
iat_messagebox:
    dq hintname_messagebox - section_start + 0x1000
    dq 0
; ---
align 8
iat_kernel32:
iat_exitprocess:
    dq hintname_exitprocess - section_start + 0x1000
    dq 0
    
; --- DLL-Namen ---
dll_msvcrt:   db 'msvcrt.dll'  , 0
dll_kernel32: db 'kernel32.dll', 0
dll_user32:   db 'user32.dll'  , 0

align 8
import_desc_msvcrt:
    dd int_msvcrt - section_start + 0x1000
    dd 0, 0
    dd dll_msvcrt - section_start + 0x1000
    dd iat_msvcrt - section_start + 0x1000

import_desc_user32:
    dd int_user32   - section_start + 0x1000
    dd 0, 0
    dd dll_user32   - section_start + 0x1000
    dd iat_user32   - section_start + 0x1000

import_desc_kernel32:
    dd int_kernel32 - section_start + 0x1000
    dd 0, 0
    dd dll_kernel32 - section_start + 0x1000
    dd iat_kernel32 - section_start + 0x1000

; Null-Descriptor
times 20 db 0

import_end:

import_rva   equ import_desc_msvcrt - section_start + 0x1000
import_size  equ import_end  - import_desc_msvcrt

;---------------------------------------------------
; Datei-Ende auf 0x400 auffüllen
;---------------------------------------------------
times 0x400-($-$$) db 0

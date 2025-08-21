; tiny64.asm – Minimal PE32+ (x64) für Windows 10+
; erzeugt: 0x400 Byte lauffähige EXE

bits 64
default rel
org 0x1000

%define IMAGEBASE    0x0000000000400000
%define FILEALIGN    0x200
%define SECTALIGN    0x1000

%define ALIGN_UP(x, a) (((x) + (a)-1) & ~((a)-1))

; Makro: pad_align alignment
; Füllt mit Nullen bis zur nächsten alignment-Grenze
%macro pad_align 1
    %assign __align %1
    %assign __cur ($-$$)
    %assign __mod __cur % __align
    %assign __pad __align - __mod
    %if __pad = __align
        %assign __pad 0
    %endif
    times __pad db 0
%endmacro

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
    dd text_raw_size                     ; SizeOfRawData
    dd 0x200                             ; PointerToRawData
    dd 0,0                               ; Reloc/Linenum
    dw 0,0
    dd 0xE0000020                        ; Characteristics: CODE|EXEC|READ|WRITE

;---------------------------------------------------
; Align bis zum Section-Start (0x200)
;---------------------------------------------------
pad_align FILEALIGN

;---------------------------------------------------
; .text Section (RVA 0x1000, Raw 0x200)
;---------------------------------------------------
section_start:

test_func:
    ; save stack pointer
    push    rbp
    mov     rbp, rsp

    ; MessageBoxA(NULL, msg, title, MB_OK)
    xor     rcx, rcx                 ; hWnd = NULL
    lea     rdx, [rel msg]           ; Text
    lea     r8,  [rel caption]       ; Caption
    mov     r9d, 0                   ; uType = MB_OK
    call    qword [rel iat_MessageBoxA]

    pop     rbp
    ret

exit_func:
    xor     ecx, ecx                ; ExitProcess(0)
    call    qword [rel iat_ExitProcess]

    pop     rbp
    ret

;---------------------------------------
; Routine: IntToString
; Eingabe: RAX = Zahl
;          RDI = Pufferadresse
; Ausgabe: Puffer enthält ASCII-Zeichen
;---------------------------------------
IntToStr:
    ; save stack pointer
    push    rbp
    mov     rbp, rsp
    
        mov   rcx, 10          ; divisor (remainder = Rest)
        mov   r10, rdi         ; scan Pointer = Anfang des Puffers
        mov   rbx, rdi         ; wir merken uns den Puffer
        
    .find_end:
        cmp   byte [r10], 0
        je    .end_found
        inc   r10
        jmp   .find_end
    .end_found:
        ; rbx zeigt jetzt auf das Nullterminator-Byte
    .convert:
        dec   r10              ; r10 -> letztes belegbares Byte (vor Terminator)
        
        ; Sonderfall: falls Zahl == 0, schreibe '0' und springe zum Ende
        test  rax, rax
        jnz   .convert_loop
        
        mov   byte [r10], '0'
        dec   r10
        jmp   .copy_back
    
    .convert_loop:
        xor   rdx, rdx
        div   rcx
        add   dl, '0'
        mov   [r10], dl         ; schreibe Ziffer
        dec   r10
        test  rax, rax
        jnz   .convert_loop
        
    .copy_back:
        ; nach der Schleife steht rbx *unter* dem ersten Ziffernbyte (oder auf Anfang-1)
        ; setze source = rbx+1, dest = rdi (Anfang des Puffers)
        lea   r8, [r10 + 1]    ; r8 = Quelle (erste Ziffer)
        mov   r9, rdi          ; r9 = Ziel (Anfang des Puffers) in rdx temporär
        
    .copy_loop:
        mov   al, [r8]
        mov   [r9], al
        inc   r8
        inc   r9
        cmp   al, 0
        jne   .copy_loop

.done:
    pop     rbp
    ret

entry:
    ; Windows x64 ABI: RCX = 1. Parameter
    ; Windows x64 ABI: bei Function-Eintritt ist RSP ≡ 8 (mod 16)
    ; reserve 32 bytes shadow + 8 für Alignment -> 40 (0x28)
    sub     rsp, 40
    
    call    test_func
    
    ; Zahl zu String konvertieren (rudimentär)
    ; a = 200 + 100
    mov     eax, 200
    add     eax, 100
    
    ; Konvertiere in String: lade Zahl aus 'a' in RAX
    lea     rdi, [rel buffer]      ; Zeiger auf den Puffer
    call    IntToStr
    
    ; printf(char*)
    lea     rcx,  [rel msg]          ; printf(const char*)
    call    qword [rel iat_printf]
    
    ; Ausgabe via MessageBoxA
    xor     rcx, rcx                 ; hWnd = NULL
    lea     rdx, [rel buffer]        ; Text
    lea     r8,  [rel caption]       ; Caption
    mov     r9d, 0                   ; uType = MB_OK
    call     qword [rel iat_MessageBoxA]
    
    ; printf(char*)
    lea     rcx,  [rel msg]          ; printf(const char*)
    call    qword [rel iat_printf]
    
    call    exit_func
    
    ; (keine Rückkehr - sollte nie erreicht werden)
    add     rsp, 40
    ret

entry_rva equ entry - section_start + 0x1000

; --- .data in writeable .text section ---
msg:
    db " Hello Tiny PE32+ (Win10 x64) OK", 10, 0
caption:
    db "Mini-PE", 0
buffer:
    db "0000000000", 0

section_end:

text_size      equ section_end - section_start        ; reale Länge
text_raw_size  equ ((text_size + FILEALIGN - 1) / FILEALIGN) * FILEALIGN ; gerundet


; Import-Tabelle --- Hint/Names ---
align 8
hintname_printf:
    dw 0
    db 'printf', 0, 0
align 8
hintname_MessageBoxA:
    dw 0
    db 'MessageBoxA', 0, 0
align 8
hintname_ExitProcess:
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
    dq hintname_MessageBoxA - section_start + 0x1000
    dq 0
; ---
align 8
int_kernel32:
    dq hintname_ExitProcess - section_start + 0x1000
    dq 0

; --- IATs (werden vom Loader gepatcht) ---    
iat_msvcrt:
iat_printf:
    dq hintname_printf - section_start + 0x1000
    dq 0
; ---
align 8
iat_user32:
iat_MessageBoxA:
    dq hintname_MessageBoxA - section_start + 0x1000
    dq 0
; ---
align 8
iat_kernel32:
iat_ExitProcess:
    dq hintname_ExitProcess - section_start + 0x1000
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
pad_align FILEALIGN

; ---------------------------------------------------------------------------
; PE32+ (x64) ohne Linker – Imports: MSVCRT.printf, USER32.MessageBoxA,
;                                   KERNEL32.ExitProcess
; Build: nasm -f bin pe64_msvcrt_user32_kernel32.asm -o hello64.exe
; Subsystem: Console
; ---------------------------------------------------------------------------

BITS 64
ORG 0

%define IMAGE_BASE   0x0000000140000000
%define FILEALIGN    0x200
%define SECTALIGN    0x1000
%define ALIGN_UP(x,a) (((x)+(a)-1)/(a))*(a)

; ===========================================================================
; DOS-Header (minimal)
; ===========================================================================
        dw 0x5A4D
        times 0x3C-2 db 0
        dd pe_header                  ; e_lfanew

; ===========================================================================
; PE-Header (PE32+) + Optional Header + Section Table
; ===========================================================================
pe_header:
        dd 0x00004550                 ; 'PE\0\0'

; COFF
        dw 0x8664                     ; AMD64
        dw 2                          ; Sections: .text, .idata
        dd 0
        dd 0
        dd 0
        dw 0x00F0                     ; SizeOfOptionalHeader (PE32+)
        dw 0x0023                     ; Characteristics: RELOCS_STRIPPED|EXECUTABLE|LAA

; Vorberechnungen
%define SIZEOF_HEADERS ALIGN_UP(headers_end - $$, FILEALIGN)

%define TEXT_VA        ALIGN_UP(headers_end - $$, SECTALIGN)
%define TEXT_RAW_PTR   SIZEOF_HEADERS
%define TEXT_VSIZE     (section_text_end - section_text_start)
%define TEXT_RAW_SIZE  ALIGN_UP(TEXT_VSIZE, FILEALIGN)
%define TEXT_VSIZE_AL  ALIGN_UP(TEXT_VSIZE, SECTALIGN)

%define IDATA_RAW_PTR  ALIGN_UP(TEXT_RAW_PTR + TEXT_RAW_SIZE, FILEALIGN)
%define IDATA_VA       ALIGN_UP(TEXT_VA + TEXT_VSIZE_AL, SECTALIGN)
%define IDATA_VSIZE    (idata_end - idata_start)
%define IDATA_RAW_SIZE ALIGN_UP(IDATA_VSIZE, FILEALIGN)
%define IDATA_VSIZE_AL ALIGN_UP(IDATA_VSIZE, SECTALIGN)

%define SIZEOF_IMAGE   ALIGN_UP(IDATA_VA + IDATA_VSIZE_AL, SECTALIGN)

; RVA-Helfer
%define RVA_TEXT(lbl)  (TEXT_VA  + ((lbl)  - section_text_start))
%define RVA_IDATA(lbl) (IDATA_VA + ((lbl)  - idata_start))

; Optional Header (PE32+)
        dw 0x020B                     ; Magic = PE32+
        db 0,0
        dd TEXT_RAW_SIZE              ; SizeOfCode
        dd IDATA_RAW_SIZE             ; SizeOfInitializedData
        dd 0                          ; SizeOfUninitializedData
        dd RVA_TEXT(_start)           ; AddressOfEntryPoint
        dd TEXT_VA                    ; BaseOfCode
        dq IMAGE_BASE                 ; ImageBase
        dd SECTALIGN                  ; SectionAlignment
        dd FILEALIGN                  ; FileAlignment
        dw 6,0                        ; OS Version 6.0
        dw 0,0                        ; Image Version
        dw 6,0                        ; Subsystem Version 6.0
        dd 0
        dd SIZEOF_IMAGE               ; SizeOfImage
        dd SIZEOF_HEADERS             ; SizeOfHeaders
        dd 0                          ; Checksum
        dw 3                          ; Subsystem: Console
        dw 0x0100                     ; DllCharacteristics: NXCompat (kein ASLR)
        dq 0x0000000000100000         ; StackReserve
        dq 0x0000000000001000         ; StackCommit
        dq 0x0000000000100000         ; HeapReserve
        dq 0x0000000000001000         ; HeapCommit
        dd 0
        dd 16

; Data Directories
; 0 Export
        dd 0,0
; 1 Import
        dd RVA_IDATA(import_dir), (import_dir_end - import_dir)
; 2 Resource
        dd 0,0
; 3 Exception
        dd 0,0
; 4 Security
        dd 0,0
; 5 Base Reloc
        dd 0,0
; 6 Debug
        dd 0,0
; 7 Architecture
        dd 0,0
; 8 Global Ptr
        dd 0,0
; 9 TLS
        dd 0,0
; 10 Load Config
        dd 0,0
; 11 Bound Import
        dd 0,0
; 12 IAT (gesamter IAT-Block)
        dd RVA_IDATA(iat_start), (iat_end - iat_start)
; 13 Delay Import
        dd 0,0
; 14 COM Descriptor
        dd 0,0
; 15 Reserved
        dd 0,0

; Section .text
        db '.text',0,0,0
        dd TEXT_VSIZE
        dd TEXT_VA
        dd TEXT_RAW_SIZE
        dd TEXT_RAW_PTR
        dd 0,0
        dw 0,0
        dd 0x60000020                 ; CODE|EXECUTE|READ

; Section .idata
        db '.idata',0,0
        dd IDATA_VSIZE
        dd IDATA_VA
        dd IDATA_RAW_SIZE
        dd IDATA_RAW_PTR
        dd 0,0
        dw 0,0
        dd 0xC0000040                 ; INIT_DATA|READ|WRITE

headers_end:

; ===========================================================================
; .text (Code)
; ===========================================================================
        times (TEXT_RAW_PTR - ($ - $$)) db 0
section_text_start:

_start:
        ; Windows x64 ABI: RCX,RDX,R8,R9 + 32 Bytes Shadow Space, 16-Byte Align
        ;sub     rsp, 64               ; Shadow + Alignment headroom
        mov     rbp, rsp
        and     rsp, -16
        sub     rsp, 32

        xor     ecx, ecx                 ; hWnd = NULL
        lea     rdx, [rel msgbox_text]           ; Text
        lea     r8,  [rel msgbox_text]           ; Caption
        mov     r9d,  r9d                ; uType = MB_OK
        mov     rax, IMAGE_BASE + RVA_IDATA(IAT_MessageBoxA)
        call    qword [rax]
        
        test    eax, eax
        jnz     .after_mb

        ; Fehlerpfad: GetLastError() und ausgeben
        mov     rax, IMAGE_BASE + RVA_IDATA(IAT_GetLastError)
        call    [rax]                    ; EAX = LastError

        mov     ecx, eax               ; %lu
        lea     rdx, [rel fmt_err]
        xor     eax, eax
        mov     rax, IMAGE_BASE + RVA_IDATA(IAT_printf)
        call    [rax]

.after_mb:
        ; ExitProcess(0)
        ;xor     ecx, ecx
        ;mov     rax, IMAGE_BASE + RVA_IDATA(IAT_ExitProcess)
        ;call    [rax]

        ; printf("Hello %s #%d\n", "world", 42);
        lea     rcx, [rel fmt]        ; RCX = format
        lea     rdx, [rel who]        ; RDX = "world"
        mov     r8d, 42               ; R8  = 42
        xor     eax, eax              ; AL = 0 (keine XMM-Args bei varargs!)
        mov     rax, IMAGE_BASE + RVA_IDATA(IAT_printf)
        call    qword [rax]
        
        ; printf("Hello %s #%d\n", "world", 42);
        lea     rcx, [rel fmt]        ; RCX = format
        lea     rdx, [rel who]        ; RDX = "world"
        mov     r8d, 42               ; R8  = 42
        xor     eax, eax              ; AL = 0 (keine XMM-Args bei varargs!)
        mov     rax, IMAGE_BASE + RVA_IDATA(IAT_printf)
        call    qword [rax]
        
        ; printf("Hello %s #%d\n", "world", 42);
        lea     rcx, [rel fmt]        ; RCX = format
        lea     rdx, [rel who]        ; RDX = "world"
        mov     r8d, 42               ; R8  = 42
        xor     eax, eax              ; AL = 0 (keine XMM-Args bei varargs!)
        mov     rax, IMAGE_BASE + RVA_IDATA(IAT_printf)
        call    qword [rax]
        
        ; printf("Hello %s #%d\n", "world", 42);
        lea     rcx, [rel fmt]        ; RCX = format
        lea     rdx, [rel who]        ; RDX = "world"
        mov     r8d, 42               ; R8  = 42
        xor     eax, eax              ; AL = 0 (keine XMM-Args bei varargs!)
        mov     rax, IMAGE_BASE + RVA_IDATA(IAT_printf)
        call    qword [rax]
        
        ; printf("Hello %s #%d\n", "world", 42);
        lea     rcx, [rel fmt]        ; RCX = format
        lea     rdx, [rel who]        ; RDX = "world"
        mov     r8d, 42               ; R8  = 42
        xor     eax, eax              ; AL = 0 (keine XMM-Args bei varargs!)
        mov     rax, IMAGE_BASE + RVA_IDATA(IAT_printf)
        call    qword [rax]
        
        ; printf("Hello %s #%d\n", "world", 42);
        lea     rcx, [rel fmt]        ; RCX = format
        lea     rdx, [rel who]        ; RDX = "world"
        mov     r8d, 42               ; R8  = 42
        xor     eax, eax              ; AL = 0 (keine XMM-Args bei varargs!)
        mov     rax, IMAGE_BASE + RVA_IDATA(IAT_printf)
        call    qword [rax]
        
        ; printf("Hello %s #%d\n", "world", 42);
        lea     rcx, [rel fmt]        ; RCX = format
        lea     rdx, [rel who]        ; RDX = "world"
        mov     r8d, 42               ; R8  = 42
        xor     eax, eax              ; AL = 0 (keine XMM-Args bei varargs!)
        mov     rax, IMAGE_BASE + RVA_IDATA(IAT_printf)
        call    qword [rax]
        
        ; printf("Hello %s #%d\n", "world", 42);
        lea     rcx, [rel fmt]        ; RCX = format
        lea     rdx, [rel who]        ; RDX = "world"
        mov     r8d, 42               ; R8  = 42
        xor     eax, eax              ; AL = 0 (keine XMM-Args bei varargs!)
        mov     rax, IMAGE_BASE + RVA_IDATA(IAT_printf)
        call    qword [rax]
        
        ; printf("Hello %s #%d\n", "world", 42);
        lea     rcx, [rel fmt]        ; RCX = format
        lea     rdx, [rel who]        ; RDX = "world"
        mov     r8d, 42               ; R8  = 42
        xor     eax, eax              ; AL = 0 (keine XMM-Args bei varargs!)
        mov     rax, IMAGE_BASE + RVA_IDATA(IAT_printf)
        call    qword [rax]

        ; printf("Hello %s #%d\n", "world", 42);
        lea     rcx, [rel fmt]        ; RCX = format
        lea     rdx, [rel who]        ; RDX = "world"
        mov     r8d, 42               ; R8  = 42
        xor     eax, eax              ; AL = 0 (keine XMM-Args bei varargs!)
        mov     rax, IMAGE_BASE + RVA_IDATA(IAT_printf)
        call    qword [rax]

        ; printf("Hello %s #%d\n", "world", 42);
        lea     rcx, [rel fmt]        ; RCX = format
        lea     rdx, [rel who]        ; RDX = "world"
        mov     r8d, 42               ; R8  = 42
        xor     eax, eax              ; AL = 0 (keine XMM-Args bei varargs!)
        mov     rax, IMAGE_BASE + RVA_IDATA(IAT_printf)
        call    qword [rax]

        ; printf("Hello %s #%d\n", "world", 42);
        lea     rcx, [rel fmt]        ; RCX = format
        lea     rdx, [rel who]        ; RDX = "world"
        mov     r8d, 42               ; R8  = 42
        xor     eax, eax              ; AL = 0 (keine XMM-Args bei varargs!)
        mov     rax, IMAGE_BASE + RVA_IDATA(IAT_printf)
        call    qword [rax]

        ; printf("Hello %s #%d\n", "world", 42);
        lea     rcx, [rel fmt]        ; RCX = format
        lea     rdx, [rel who]        ; RDX = "world"
        mov     r8d, 42               ; R8  = 42
        xor     eax, eax              ; AL = 0 (keine XMM-Args bei varargs!)
        mov     rax, IMAGE_BASE + RVA_IDATA(IAT_printf)
        call    qword [rax]

        ; printf("Hello %s #%d\n", "world", 42);
        lea     rcx, [rel fmt]        ; RCX = format
        lea     rdx, [rel who]        ; RDX = "world"
        mov     r8d, 42               ; R8  = 42
        xor     eax, eax              ; AL = 0 (keine XMM-Args bei varargs!)
        mov     rax, IMAGE_BASE + RVA_IDATA(IAT_printf)
        call    qword [rax]

        ; printf("Hello %s #%d\n", "world", 42);
        lea     rcx, [rel fmt]        ; RCX = format
        lea     rdx, [rel who]        ; RDX = "world"
        mov     r8d, 42               ; R8  = 42
        xor     eax, eax              ; AL = 0 (keine XMM-Args bei varargs!)
        mov     rax, IMAGE_BASE + RVA_IDATA(IAT_printf)
        call    qword [rax]

        ; printf("Hello %s #%d\n", "world", 42);
        lea     rcx, [rel fmt]        ; RCX = format
        lea     rdx, [rel who]        ; RDX = "world"
        mov     r8d, 42               ; R8  = 42
        xor     eax, eax              ; AL = 0 (keine XMM-Args bei varargs!)
        mov     rax, IMAGE_BASE + RVA_IDATA(IAT_printf)
        call    qword [rax]

        ; printf("Hello %s #%d\n", "world", 42);
        lea     rcx, [rel fmt]        ; RCX = format
        lea     rdx, [rel who]        ; RDX = "world"
        mov     r8d, 42               ; R8  = 42
        xor     eax, eax              ; AL = 0 (keine XMM-Args bei varargs!)
        mov     rax, IMAGE_BASE + RVA_IDATA(IAT_printf)
        call    qword [rax]

        ; printf("Hello %s #%d\n", "world", 42);
        lea     rcx, [rel fmt]        ; RCX = format
        lea     rdx, [rel who]        ; RDX = "world"
        mov     r8d, 42               ; R8  = 42
        xor     eax, eax              ; AL = 0 (keine XMM-Args bei varargs!)
        mov     rax, IMAGE_BASE + RVA_IDATA(IAT_printf)
        call    qword [rax]

        ; printf("Hello %s #%d\n", "world", 42);
        lea     rcx, [rel fmt]        ; RCX = format
        lea     rdx, [rel who]        ; RDX = "world"
        mov     r8d, 42               ; R8  = 42
        xor     eax, eax              ; AL = 0 (keine XMM-Args bei varargs!)
        mov     rax, IMAGE_BASE + RVA_IDATA(IAT_printf)
        call    qword [rax]

        ; printf("Hello %s #%d\n", "world", 42);
        lea     rcx, [rel fmt]        ; RCX = format
        lea     rdx, [rel who]        ; RDX = "world"
        mov     r8d, 42               ; R8  = 42
        xor     eax, eax              ; AL = 0 (keine XMM-Args bei varargs!)
        mov     rax, IMAGE_BASE + RVA_IDATA(IAT_printf)
        call    qword [rax]

        ; printf("Hello %s #%d\n", "world", 42);
        lea     rcx, [rel fmt]        ; RCX = format
        lea     rdx, [rel who]        ; RDX = "world"
        mov     r8d, 42               ; R8  = 42
        xor     eax, eax              ; AL = 0 (keine XMM-Args bei varargs!)
        mov     rax, IMAGE_BASE + RVA_IDATA(IAT_printf)
        call    qword [rax]

        ; printf("Hello %s #%d\n", "world", 42);
        lea     rcx, [rel fmt]        ; RCX = format
        lea     rdx, [rel who]        ; RDX = "world"
        mov     r8d, 42               ; R8  = 42
        xor     eax, eax              ; AL = 0 (keine XMM-Args bei varargs!)
        mov     rax, IMAGE_BASE + RVA_IDATA(IAT_printf)
        call    qword [rax]

        ; printf("Hello %s #%d\n", "world", 42);
        lea     rcx, [rel fmt]        ; RCX = format
        lea     rdx, [rel who]        ; RDX = "world"
        mov     r8d, 42               ; R8  = 42
        xor     eax, eax              ; AL = 0 (keine XMM-Args bei varargs!)
        mov     rax, IMAGE_BASE + RVA_IDATA(IAT_printf)
        call    qword [rax]

        ; printf("Hello %s #%d\n", "world", 42);
        lea     rcx, [rel fmt]        ; RCX = format
        lea     rdx, [rel who]        ; RDX = "world"
        mov     r8d, 42               ; R8  = 42
        xor     eax, eax              ; AL = 0 (keine XMM-Args bei varargs!)
        mov     rax, IMAGE_BASE + RVA_IDATA(IAT_printf)
        call    qword [rax]

        mov     rcx, qword 0                 ; hWnd = NULL
        lea     rdx, [rel msgbox_text]           ; Text
        lea     r8,  [rel msgbox_text]           ; Caption
        mov     r9,  dword 0                ; uType = MB_OK
        mov     rax, IMAGE_BASE + RVA_IDATA(IAT_MessageBoxA)
        call    qword [rax]

        ; ExitProcess(0);
        xor     ecx, ecx
        mov     rax, IMAGE_BASE + RVA_IDATA(IAT_ExitProcess)
        call    qword [rax]

; konstante Daten in .text (nur gelesen)
fmt:            db "Hello %s #%d", 13,10,0
who:            db "world",0
fmt_err:        db "MessageBoxA failed, GetLastError=%lu",13,10,0
msgbox_text:    db "Alles fertig.",0
msgbox_caption: db "Pure NASM PE64",0

section_text_end:

; ===========================================================================
; .idata (Imports)
; ===========================================================================
        times (IDATA_RAW_PTR - ($ - $$)) db 0
idata_start:

; --- Import Directory mit drei Deskriptoren + Terminator
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
IAT_MessageBoxA:    dq RVA_IDATA(HN_MessageBoxA)
                    dq 0

iat_msvcrt:
IAT_printf:         dq RVA_IDATA(HN_printf)
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
dll_kernel32:       db 'KERNEL32.DLL',0
dll_user32:         db 'USER32.DLL',0
dll_msvcrt:         db 'MSVCRT.DLL',0

idata_end:

; Optional auf FileAlignment runden
        times (ALIGN_UP($ - $$, FILEALIGN) - ($ - $$)) db 0

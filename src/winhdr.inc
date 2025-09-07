;---------------------------------------------------
; NT-Header
;---------------------------------------------------

pe_header:
    db 'P','E',0,0                      ; Signature

    ; File Header
    dw 0x8664                           ; Machine = AMD64
    dw 2                                ; NumberOfSections
    dd 0                                ; TimeDateStamp
    dd 0,0                              ; PointerToSymbolTable, NumberOfSymbols
    dw 0xF0                             ; SizeOfOptionalHeader
    dw 0x023                            ; Characteristics (EXECUTABLE|LAA)

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

%define RVA_TEXT(lbl)  (TEXT_VA  + ((lbl)  - section_text_start))
%define RVA_IDATA(lbl) (IDATA_VA + ((lbl)  - idata_start))

    ; Optional Header (PE32+)
    dw 0x20B                            ; Magic = PE32+
    db 0,0                              ; LinkerVersion
    dd TEXT_RAW_SIZE                    ; SizeOfCode
    dd IDATA_RAW_SIZE                   ; SizeOfInit
    dd 0                                ; UninitData
    dd RVA_TEXT(_start)                 ; AddressOfEntryPoint
    dd TEXT_VA                          ; BaseOfCode
    dq IMAGEBASE                        ; ImageBase
    dd SECTALIGN                        ; SectionAlignment
    dd FILEALIGN                        ; FileAlignment
    dw 6,0                              ; OS Version
    dw 0,0                              ; Image Version
    dw 6,0                              ; Subsystem Version
    dd 0                                ; Win32VersionValue
    dd SIZEOF_IMAGE                     ; SizeOfImage (Header + 1 Section)
    dd SIZEOF_HEADERS                   ; SizeOfHeaders
    dd 0                                ; CheckSum
    dw 3                                ; Subsystem = CUI
    dw 0x0100                           ; DllCharacteristics
    dq 0x100000                         ; SizeOfStackReserve
    dq 0x1000                           ; SizeOfStackCommit
    dq 0x100000                         ; SizeOfHeapReserve
    dq 0x1000                           ; SizeOfHeapCommit
    dd 0                                ; LoaderFlags
    dd 16                               ; NumberOfRvaAndSizes

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
    ; 5 Base Reloc (no references)
    dd 0,0
    ; 6 Debug
    dd 0,0
    ; 7 Archicteure
    dd 0,0
    ; 8 Global Ptr
    dd 0,0
    ; 9 TLS
    dd 0,0
    ; 10 Load Config
    dd 0,0
    ; 11 Bound Import
    dd 0,0
    ; 12 IAT
    dd RVA_IDATA(iat_start), (iat_end - iat_start)
    ; 13 Delay Import
    dd 0,0
    ; 14 COM Descriptor
    dd 0,0
    ; 15 Reserved
    dd 0,0

    ; Section Header (.text)
    db '.text',0,0,0                     ; Name
    dd TEXT_VSIZE                        ; VirtualSize
    dd TEXT_VA                           ; VirtualAddress
    dd TEXT_RAW_SIZE                     ; SizeOfRawData
    dd TEXT_RAW_PTR                      ; PointerToRawData
    dd 0,0                               ; Reloc/Linenum
    dw 0,0
    dd 0xE0000020                        ; Characteristics: CODE|EXEC|READ|WRITE
    
    ; --- Section Table: .idata
    db '.idata',0,0
    dd IDATA_VSIZE
    dd IDATA_VA
    dd IDATA_RAW_SIZE
    dd IDATA_RAW_PTR
    dd 0,0
    dw 0,0
    dd 0xC0000040                        ; INIT_DATA|READ|WRITE

headers_end:

;---------------------------------------------------
; Align bis zum Section-Start (0x200)
;---------------------------------------------------
times (TEXT_RAW_PTR - ($ - $$)) db 0


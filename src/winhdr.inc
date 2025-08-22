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

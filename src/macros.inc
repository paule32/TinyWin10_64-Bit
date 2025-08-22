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

%macro HINTNAME 1-*
    %rep %0
        %defstr _str %1
        align 8
        hintname_%+%1:
        dw 0
        db _str, 0, 0
        %rotate 1
    %endrep
%endmacro

; ------------------------
; Import Name Table Descriptor
; ------------------------
%macro INT_TABLE 2-*
align 8
int_%+%1:
    %rotate %0
    %rep %0-1
        int_%+%2:
        dq hintname_%+%2 - section_start + 0x1000
        %rotate 1
    %endrep
    dq 0
%endmacro

; ------------------------
; Import Address Descriptor
; ------------------------
%macro IAT_TABLE 2-*
iat_%+%1:
    %rotate %0
    %rep %0-1
        iat_%+%2:
        dq hintname_%+%2 - section_start + 0x1000
        %rotate 1
    %endrep
    dq 0
%endmacro

; ------------------------
; Import Descriptor
; ------------------------
%macro IMPORT_DESC 1
import_desc_%+%1:
    dd int_%+%1 - section_start + 0x1000
    dd 0,0
    dd dll_%+%1 - section_start + 0x1000
    dd iat_%+%1 - section_start + 0x1000
%endmacro

%macro IMPORT_DLL 1
    %defstr _str %1
    dll_%+%1:   db _str, '.dll'  , 0
%endmacro

%include 'asmacro.inc'
%include 'winfunc.inc'

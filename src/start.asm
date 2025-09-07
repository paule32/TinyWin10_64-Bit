;---------------------------------------------------
; \file  start.asm
; \note  (c) 2025 by Jens Kallup - paule32
;        all rights reserved.
;
; \desc  Create a tiny MS-Windows 11 64-bit Pro EXE.
;---------------------------------------------------
%include 'bitsxx.inc'
%include 'macros.inc'

%include 'locales.deu'       ; user locales

;---------------------------------------------------
; DOS / PE-Header
;---------------------------------------------------
%include 'doshdr.inc'
%include 'winhdr.inc'

;---------------------------------------------------
; .text Section (RVA 0x1000, Raw 0x200)
;---------------------------------------------------
%include 'code64.asm'
%include 'imports.inc'

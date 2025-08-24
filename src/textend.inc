;---------------------------------------------------
; \file  textend.inc
; \note  (c) 2025 by Jens Kallup - paule32
;        all rights reserved.
;
; \desc  Create a tiny MS-Windows 11 64-bit Pro EXE.
;---------------------------------------------------
section_end:

text_size      equ section_end - section_start        ; reale Länge
text_raw_size  equ ((text_size + FILEALIGN - 1) / FILEALIGN) * FILEALIGN ; gerundet

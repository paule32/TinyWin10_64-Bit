;---------------------------------------------------
; \file  fileend.inc
; \note  (c) 2025 by Jens Kallup - paule32
;        all rights reserved.
;
; \desc  Create a tiny MS-Windows 11 64-bit Pro EXE.
;---------------------------------------------------
pad_align FILEALIGN

import_end:

import_rva   equ import_desc_msvcrt - section_start + 0x1000
import_size  equ import_end  - import_desc_msvcrt

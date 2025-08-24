;---------------------------------------------------
; \file  bits64.inc
; \note  (c) 2025 by Jens Kallup - paule32
;        all rights reserved.
;
; \desc  Create a tiny MS-Windows 11 64-bit Pro EXE.
;---------------------------------------------------
bits 64
default rel
org 0

%define IMAGEBASE    0x0000000000400000
%define FILEALIGN    0x200
%define SECTALIGN    0x1000

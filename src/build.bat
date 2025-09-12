:: ----------------------------------------------------------------------------
:: \file  build.bat - MS-DOS Windows-Console Batch File to create .exe cutable.
:: \note  (c) 2025 by Jens Kallup - paule32
::        all rights reserved.
::
:: \desc  Create a tiny MS-Windows 11 64-bit Pro EXE.
:: ----------------------------------------------------------------------------
@echo on
nasm -f bin -o start.exe start.asm
python time_patch.py start.exe --recalc-checksum -v

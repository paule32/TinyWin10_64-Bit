:: ----------------------------------------------------------------------------
:: \file  build.bat - MS-DOS Windows-Console Batch File to create .exe cutable.
:: \note  (c) 2025 by Jens Kallup - paule32
::        all rights reserved.
::
:: \desc  Create a tiny MS-Windows 11 64-bit Pro EXE.
:: ----------------------------------------------------------------------------
@echo on
python dllord.py --dll kernel32.dll --dll-dir C:\Windows\System32 --out-po ord_kenrel32.po
python dllord.py --dll user32.dll   --dll-dir C:\Windows\System32 --out-po ord_user32.po

gzip -9 -f ord_kenrel32.mo
gzip -9 -f ord_user32.po

nasm -f bin -o start.exe start.asm
python time_patch.py start.exe --recalc-checksum -v

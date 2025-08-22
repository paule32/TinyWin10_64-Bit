; Import-Tabelle --- Hint/Names ---
HINTNAME printf, MessageBoxA, ExitProcess

; --- INTs (Import Name Table, 64-bit Thunks) ---
INT_TABLE msvcrt, printf
INT_TABLE user32, MessageBoxA
INT_TABLE kernel32, ExitProcess

; --- IATs (werden vom Loader gepatcht) ---
IAT_TABLE msvcrt, printf
IAT_TABLE user32, MessageBoxA
IAT_TABLE kernel32, ExitProcess

; --- DLL-Namen ---
IMPORT_DLL msvcrt
IMPORT_DLL user32
IMPORT_DLL kernel32

align 8
IMPORT_DESC msvcrt
IMPORT_DESC user32
IMPORT_DESC kernel32

; Null-Descriptor
times 20 db 0

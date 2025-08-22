print_string:
    ; RCX = pointer auf String
    push    rcx
    mov     ecx, -11                ; STD_OUTPUT_HANDLE
    RELCALL GetStdHandle
    mov     r9d, 0                  ; lpReserved = NULL
    mov     r8d, 0                  ; lpNumberOfCharsWritten = NULL
    pop     rcx                     ; rcx = lpBuffer
    mov     rdx, rcx                ; rdx = lpBuffer
    mov     rcx, rcx                ; (rcx enthält bereits den Pointer, aber für Klarheit)
    call    strlen                  ; Rückgabewert in RAX
    mov     r8, rax                 ; r8 = Länge des Strings
    RELCALL WriteConsoleA
    ret
 
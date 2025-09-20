; ( -- )
; Wait for the FDC's busy bit to clear
forthword "DWAITB", 6, DWAITB
    dw LIT
    dw '['
    dw EMIT
    dw LIT
    dw 0xe4
    dw PORTIN
    dw LIT
    dw 0x01
    dw FAND
    dw LIT
    dw 13
    dw NEGATE
    dw LIT
    dw 0
    dw SELECT
    dw BRANCH
    dw LIT
    dw ']'
    dw EMIT
    dw EXIT

; ( track -- )
; Seek the disk to the specified track
forthword "DSEEK", 5, DSEEK
    dw LIT
    dw 0xe5
    dw PORTOUT
    dw LIT
    dw 00011101b
    dw LIT
    dw 0xe4
    dw DWAITB
    dw EXIT

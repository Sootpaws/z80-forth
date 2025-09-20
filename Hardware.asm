; ( -- )
; Initialize all hardware devices
forthword "INITHW", 6, INITHW
    dw LIT
    dw hw_setup_table
    dw LIT
    dw 14
    dw WRITEPORTS
    ; The first character printed to serial gets dropped
    dw LIT
    dw ' '
    dw TOSRL
    dw EXIT

; ( start pairs -- )
; Write a sequence of values to I/O ports
forthword "WRITEPORTS", 10, WRITEPORTS
    ; Check for end
    dw DUP
    dw LIT
    dw 1
    dw LIT
    dw 0
    dw SELECT
    dw BRANCH
    dw EXIT
    ; Run step
    dw SWAP
    dw DUP
    dw LOADC
    dw SWAP
    dw INCREMENT
    dw DUP
    dw LOADC
    dw SWAP
    dw INCREMENT
    dw TOR
    dw PORTOUT
    dw FROMR
    dw SWAP
    dw DECREMENT
    ; Loop
    dw LIT
    dw 26
    dw NEGATE
    dw BRANCH

hw_setup_table:
    ; Initialize the CTC
    db 0x8                  ; CTC interrupt vector base
    db 0xf0
                            ; Channel 3: Triggered on keyboard key press
    db 11010111b            ; Interrupts enabled, counter mode, prescaler
    db 0xf3                 ;     ignored, rising edge, trigger ignored,
                            ;     set time constant, reset channel, control word
    db 0x1                  ; Send time constant
    db 0xf3
    ; Initialize the SIO
    ; Channel B
    db 0x18                 ; Reset channel
    db 0xf7
    db 0x2                  ; Select register 2
    db 0xf7
    db low int_vec_sio      ; Interrupt vector
    db 0xf7
    db 0x84                 ; Select register 4, reset external/status interrupt
    db 0xf7
    db 01000101b            ; x16 clock, sync ignored, 1 stop bit, parity odd,
    db 0xf7                 ;     parity enable
    db 0x1                  ; Select register 1
    db 0xf7
    db 00010100b            ; Wait/ready diabled, interrupt on rx -
    db 0xf7                 ;     error=special, vector by status, diable
                            ;     transmit interrupts, disable
                            ;     external interrupts
    db 0x5                  ; Select register 5
    db 0xf7
    db 01101000b            ; DTR off, 8 bits/char tx, no break, enable tx,
    db 0xf7                 ; SDLC CRC, RTS off, CRC disabled
    db 0x3                  ; Select register 3
    db 0xf7
    db 11000001b            ; 8 bits/char rx, auto enable off, no hunt, no CRC,
    db 0xf7                 ; address search mode disabled, sync load inhibit
                            ; disabled, rx enabled

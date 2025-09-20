; ( byte port -- )
; Write a byte to an I/O port
asmword "PORTOUT", 7, PORTOUT
    pop bc                  ; Get port
    pop hl                  ; Get byte
    out (c),l               ; Output
    NEXT

; ( port -- byte )
; Read a byte from an I/O port
asmword "PORTIN", 6, PORTIN
    pop  bc                 ; Get port
    in   a,(c)              ; Input
    ld   bc,0
    ld   c,a
    push bc
    NEXT

; ( index -- )
; Position the cursor on the CRT
forthword "CRTCURSET", 9, CRTCURSET
    dw DUP          ; Update stored cursor position
    dw LIT
    dw v_CURSOR
    dw STORE
    dw DUP          ; Update on-screen cursor
    dw LIT          ; Low byte
    dw 0x0f         ; CRTC address register
    dw LIT
    dw 0xfc
    dw PORTOUT
    dw LIT          ; CRTC data register
    dw 0xfd
    dw PORTOUT
    dw HBYTE        ; High byte
    dw LIT
    dw 0x0e         ; CRTC address register
    dw LIT
    dw 0xfc
    dw PORTOUT
    dw LIT          ; CRTC data register
    dw 0xfd
    dw PORTOUT
    dw EXIT

; ( char -- )
; Print a character to the CRT
forthword ">CRT", 4, TOCRT
    dw LIT          ; Clear top byte of character
    dw 0x00ff
    dw FAND
    dw DUP          ; Is this a newline?
    dw LIT
    dw 0xff         ; Use the inverted +- character to symbolize newlines
    dw EQEQ
    dw LIT
    dw 16
    dw LIT
    dw 0
    dw SELECT
    dw BRANCH
    dw LIT          ; Add blank space character to high part of word
    dw 0x2000
    dw PLUS
    dw LIT          ; Get cursor position
    dw v_CURSOR
    dw LOAD
    dw DUP          ; Get new cursor position
    dw LIT
    dw 1
    dw PLUS
    dw CRTCURSET    ; Update cursor position
    dw LIT          ; Calculate destination address
    dw VBASE
    dw PLUS
    dw STORE        ; Write character to video memory
    dw EXIT
    dw DROP
    dw LIT          ; Newline handler, get current cursor position
    dw v_CURSOR
    dw LOAD
    dw LIT          ; Calculate line number
    dw 80           ; 80 columns
    dw DIVU
    dw INCREMENT    ; Start of next column
    dw LIT          ; Calculate index
    dw 80           ; 80 columns
    dw STARU
    dw CRTCURSET    ; Set position
    dw EXIT

; ( char -- )
; Print a character to the serial port
forthword ">SRL", 4, TOSRL
    ; Remap newlines
    dw DUP
    dw LIT
    dw 0xff
    dw EQEQ
    dw LIT
    dw 0
    dw LIT
    dw 3
    dw SELECT
    dw BRANCH
    dw DROP
    dw LIT
    dw 10
    ; Wait for serial port to be ready
    dw LIT
    dw 0xf7
    dw PORTIN
    dw LIT
    dw 00000100b
    dw FAND
    dw LIT
    dw 0
    dw LIT
    dw 13
    dw NEGATE
    dw SELECT
    dw BRANCH
    ; Write character to serial port
    dw LIT
    dw 0xf5
    dw PORTOUT
    dw EXIT

; TODO: Make this redirectable
forthword "EMIT", 4, EMIT
    ; dw DUP
    dw TOCRT
    ; dw TOSRL
    dw EXIT

; ( -- char TRUE | FALSE )
; Try to read a character from the keyboard. Returns the read character and
; true if a character was read, or false if no character was available
forthword "?KBD>", 5, MFROMKBD
    ; Get current input buffer pointer
    dw LIT
    dw v_IBUFR
    dw LOAD
    ; Character availilable?
    dw DUP
    dw LIT
    dw v_IBUFW
    dw LOAD
    dw EQEQ
    dw LIT
    dw 0
    dw LIT
    dw 4
    dw SELECT
    dw BRANCH
    ; No, exit
    dw DROP
    dw LIT
    dw 0
    dw EXIT
    ; Yes
    ; Increment pointer
    dw DUP
    dw INCREMENT
    ; Check for wraparound ( IBUFR + 1 == IBUF_END )
    dw DUP
    dw LIT
    dw c_IBUFE
    dw EQEQ
    dw LIT
    dw 0
    dw LIT
    dw 3
    dw SELECT
    dw BRANCH
    ; Label: wrap
    ; Wrap read pointer
    ; Drop old pointer
    dw DROP
    ; Replace with new pointer
    dw LIT
    dw c_IBUFS
    ; Label: continue
    ; Update pointer
    dw LIT
    dw v_IBUFR
    dw STORE
    ; Read character
    dw LOADC
    ; Remap newlines
    dw DUP
    dw LIT
    dw 13
    dw EQEQ
    dw LIT
    dw 0
    dw LIT
    dw 3
    dw SELECT
    dw BRANCH
    dw DROP
    dw LIT
    dw 0xff
    ; Character available
    dw LIT
    dw 0xffff
    dw EXIT

; ( -- char TRUE | FALSE )
; Try to read a character from the serial device. Returns the read character and
; true if a character was read, or false if no character was available
forthword "?SRL>", 5, MFROMSRL
    ; Get current input buffer pointer
    dw LIT
    dw v_SBUFR
    dw LOAD
    ; Character availilable?
    dw DUP
    dw LIT
    dw v_SBUFW
    dw LOAD
    dw EQEQ
    dw LIT
    dw 0
    dw LIT
    dw 4
    dw SELECT
    dw BRANCH
    ; No, exit
    dw DROP
    dw LIT
    dw 0
    dw EXIT
    ; Yes
    ; Increment pointer
    dw DUP
    dw INCREMENT
    ; Check for wraparound ( SBUFR + 1 == SBUF_END )
    dw DUP
    dw LIT
    dw c_SBUFE
    dw EQEQ
    dw LIT
    dw 0
    dw LIT
    dw 3
    dw SELECT
    dw BRANCH
    ; Label: wrap
    ; Wrap read pointer
    ; Drop old pointer
    dw DROP
    ; Replace with new pointer
    dw LIT
    dw c_SBUFS
    ; Label: continue
    ; Update pointer
    dw LIT
    dw v_SBUFR
    dw STORE
    ; Read character
    dw LOADC
    ; Remap newlines
    dw DUP
    dw LIT
    dw 10
    dw EQEQ
    dw LIT
    dw 0
    dw LIT
    dw 3
    dw SELECT
    dw BRANCH
    dw DROP
    dw LIT
    dw 0xff
    ; Character available
    dw LIT
    dw 0xffff
    dw EXIT

; ( -- char TRUE | FALSE )
; Try to read a character from either the keyboard or the serial port. Returns
; the read character and true if a character was read, or false if no character
; was available
forthword "?K|S>", 5, MFROMKORS
    ; Check the keyboard
    dw MFROMKBD
    ; Character recieved?
    dw DUP
    dw LIT
    dw 2
    dw LIT
    dw 0
    dw SELECT
    dw BRANCH
    ; Nothing on keyboard, try serial
    dw DROP
    dw MFROMSRL
    dw EXIT

; ( ?xxx> -- char )
; Repeatedly call a word until it returns true
forthword "POLL", 4, POLL
    dw DUP
    dw EXECUTE
    dw LIT
    dw 0
    dw LIT
    dw 9
    dw NEGATE
    dw SELECT
    dw BRANCH
    dw SWAP
    dw DROP
    dw EXIT

; ( -- char )
; Read a character from the current input device
forthword "KEY", 3, KEY
    dw LIT
    dw MFROMKORS
    dw POLL
    dw DUP
    dw EMIT
    dw EXIT

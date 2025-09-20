; ( -- )
; Print a status message
forthword "STATUS", 6, STATUS
    ; Version and DSP
    dw LIT
    dw status_1
    dw LIT
    dw 29
    dw TELL
    dw DSPLOAD
    dw INCREMENT
    dw DOTX
    ; DSP depth
    dw LIT
    dw status_depth
    dw LIT
    dw 6
    dw TELL
    dw DSPZERO
    dw DSPLOAD
    dw INCREMENT
    dw INCREMENT
    dw INCREMENT
    dw MINUS
    dw FSHR
    dw DOT
    ; RSP
    dw LIT
    dw status_2
    dw LIT
    dw 6
    dw TELL
    dw RSPLOAD
    dw DOTX
    ; RSP depth
    dw LIT
    dw status_depth
    dw LIT
    dw 6
    dw TELL
    dw RSPLOAD
    dw RSPZERO
    dw MINUS
    dw FSHR
    dw DOT
    ; HERE
    dw LIT
    dw status_3
    dw LIT
    dw 7
    dw TELL
    dw HERE
    dw LOAD
    dw DOTX
    ; HERE depth
    dw LIT
    dw status_depth
    dw LIT
    dw 6
    dw TELL
    dw HERE
    dw LOAD
    dw HEREZERO
    dw MINUS
    dw DOT
    ; Words
    dw LIT
    dw status_4
    dw LIT
    dw 8
    dw TELL
    ; Count words
    dw LIT
    dw 0
    dw LATEST
    dw DUP
    dw LIT
    dw 0
    dw LIT
    dw 8
    dw SELECT
    dw BRANCH
    dw LOAD
    dw TOR
    dw INCREMENT
    dw FROMR
    dw LIT
    dw 15
    dw NEGATE
    dw BRANCH
    ; Print number of words
    dw DROP
    dw DOT
    ; TODO: this
    dw CR
    dw EXIT

; ( value addr len -- index | xffff )
; Find the index of $value in the region $addr $len. Returns -1 if not found
forthword "INDEX_OF", 8, INDEX_OF
    dw LIT
    dw 0
    ; ( value addr len index )
    ; Check for end of literal
    dw OVER
    dw LIT
    dw 5
    dw LIT
    dw 0
    dw SELECT
    dw BRANCH
    ; End reached, not found
    dw TWODROP
    dw TWODROP
    dw LIT
    dw 0xffff
    dw EXIT
    ; Check for match
    ; ( value addr len index )
    dw LIT
    dw 4
    dw PICK
    dw LIT
    dw 4
    dw PICK
    dw LOADC
    dw EQEQ
    dw LIT
    dw 0
    dw LIT
    dw 5
    dw SELECT
    dw BRANCH
    ; Value matches, found
    dw TOR
    dw TWODROP
    dw DROP
    dw FROMR
    dw EXIT
    ; Not match, advance
    dw TOR
    dw TOR
    dw INCREMENT
    dw FROMR
    dw DECREMENT
    dw FROMR
    dw INCREMENT
    ; And loop
    dw LIT
    dw 42
    dw NEGATE
    dw BRANCH

; ( src length dest -- )
; ( Copy $length words from $src to $dest )
forthword "COPY", 4, COPY
    ; ( Setup stack )
    dw SWAP
    ; ( Loop )
        ; ( src dest length )
        ; ( Check if done )
        dw DUP
    dw LIT
    dw 0
    dw LIT
    dw 15
    dw SELECT
    dw BRANCH
        ; ( Not done )
        ; ( Copy word )
        dw TOR
        dw OVER
        dw LOAD
        dw OVER
        dw STORE
        ; ( Update pointers and length )
        dw TOR
        dw INCREMENT
        dw FROMR
        dw INCREMENT
        dw FROMR
        dw DECREMENT
    dw LIT
    dw 22
    dw NEGATE
    dw BRANCH
    ; ( Done )
    dw TWODROP
    dw DROP
    dw EXIT

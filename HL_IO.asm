; ( -- )
; Print a space
forthword "SPACE", 5, FSPACE
    dw LIT
    dw ' '
    dw EMIT
    dw EXIT

; ( -- )
; Print a newline
forthword "CR", 2, CR
    dw LIT
    dw 0xff
    dw EMIT
    dw EXIT

; ( number -- digit )
; Convert a 0x0-0xf number into a character
forthword "DIGIT", 5, DIGIT
    dw LIT
    dw digits
    dw PLUS
    dw LOAD
    dw EXIT

; ( number base -- )
; Print a number in a specific base
forthword ".C", 2, DOTC
    ; Setup stack
    dw SWAP
    dw LIT
    dw 0
    dw SWAP
    ; Convert loop
    ; ( base digits number )
    ; Get digit
    dw LIT
    dw 3
    dw PICK
    dw DIVMODU
    dw TOR
    ; Increment digit count
    dw TOR
    dw INCREMENT
    dw FROMR
    ; Loop if number != 0
    dw DUP
    dw LIT
    dw 16
    dw NEGATE
    dw LIT
    dw 0
    dw SELECT
    dw BRANCH
    dw DROP
    dw SWAP
    dw DROP
    ; Printing loop
    ; ( digits )
    ; Done?
    dw DUP
    dw LIT
    dw 0
    dw LIT
    dw 8
    dw SELECT
    dw BRANCH
    ; Print digit
    dw FROMR
    dw DIGIT
    dw EMIT
    ; Decrement counter
    dw DECREMENT
    ; Loop
    dw LIT
    dw 15
    dw NEGATE
    dw BRANCH
    ; Drop digit counter and return
    dw DROP
    dw EXIT

; ( number -- )
; Print a number in binary
forthword ".b", 2, DOTB
    dw LIT
    dw 'b'
    dw EMIT
    dw LIT
    dw 2
    dw DOTC
    dw FSPACE
    dw EXIT

; ( number -- )
; Print a number in hexadecimal
forthword ".x", 2, DOTX
    dw LIT
    dw 'x'
    dw EMIT
    dw LIT
    dw 16
    dw DOTC
    dw FSPACE
    dw EXIT

; ( number -- )
; Print a number in unsigned decimal
forthword ".", 1, DOT
    dw LIT
    dw 10
    dw DOTC
    dw FSPACE
    dw EXIT

; ( addr len -- )
; ( Print a string)
forthword "TELL", 4, TELL
    ; Loop start
    ; Done?
    dw DUP
    dw LIT
    dw 2
    dw LIT
    dw 0
    dw SELECT
    dw BRANCH
    ; Length == 0, done
    dw TWODROP
    dw EXIT
    ; Continue loop
    dw TOR
    ; Print character
    dw DUP
    dw LOADC
    dw EMIT
    ; Next character
    dw INCREMENT
    dw FROMR
    ; Update length
    dw DECREMENT
    dw LIT
    dw 20
    dw NEGATE
    dw BRANCH

; ( char -- is_whitespace )
; Check if a character is considered whitespace (space or newline)
forthword "?WHITESPACE", 11, MWHITESPACE
    dw DUP
    dw LIT
    dw 32       ; Space
    dw EQEQ
    dw SWAP
    dw LIT
    dw 0xff     ; Newline
    dw EQEQ
    dw FOR
    dw EXIT

; ( -- addr len )
; Read a Forth word from input into the word buffer
forthword "WORD", 4, FWORD
    ; Push the string pointer
    dw LIT
    dw c_WBUF
    ; Push the write pointer
    dw DUP
    ; Whitespace loop
    ; Get next character
    dw KEY
    ; Check if whitespace
    dw DUP
    dw MWHITESPACE
    ; Continue to read loop if not whitespace
    dw LIT
    dw 0
    dw LIT
    dw 5
    dw SELECT
    dw BRANCH
    ; Discard character and loop
    dw DROP
    dw LIT
    dw 14
    dw NEGATE
    dw BRANCH
    ; Read loop
    ; Check for end of word
    dw DUP
    dw MWHITESPACE
    dw LIT
    dw 8
    dw LIT
    dw 0
    dw SELECT
    dw BRANCH
    ; Normal character
    ; Write to buffer
    dw OVER
    dw STORE
    ; Increment write pointer
    dw INCREMENT
    ; Get the next character
    dw KEY
    ; Loop
    dw LIT
    dw 16
    dw NEGATE
    dw BRANCH
    ; End of word
    ; Drop pressed key (space)
    dw DROP
    ; Calculate length and exit
    dw LIT
    dw c_WBUF
    dw MINUS
    dw EXIT

; ( addr len base -- value valid )
; Parse the string $adder $len as a base $base number
forthword "PARSE_NUM", 9, PARSE_NUM
    ; Set initial value
    dw LIT
    dw 0x0000
    ; ( addr len base value )
    ; Check for end of literal
    dw LIT
    dw 3
    dw PICK
    dw LIT
    dw 7
    dw LIT
    dw 0
    dw SELECT
    dw BRANCH
    ; End of literal
    dw TOR
    dw TWODROP
    dw DROP
    dw FROMR
    dw LIT
    dw 0xffff
    dw EXIT
    ; ( addr len base value )
    ; Shift current value up one digit
    dw OVER
    dw STARU
    ; Get first digit of literal
    dw LIT
    dw 4
    dw PICK
    dw LOADC
    ; ( addr len base value digit_char )
    ; Get value of digit
    dw LIT
    dw digits
    dw LIT
    dw 4
    dw PICK
    dw INDEX_OF
    ; ( addr len base value digit_value )
    ; Check for invalid digit
    dw DUP
    dw LIT
    dw 0xffff
    dw EQEQ
    dw LIT
    dw 0
    dw LIT
    dw 5
    dw SELECT
    dw BRANCH
    ; Not valid
    dw TWODROP
    dw TWODROP
    dw LIT
    dw 0
    dw EXIT
    ; Add digit to value
    dw PLUS
    ; ( addr len base value )
    ; Advance to next character
    dw TOR
    dw TOR
    dw TOR
    dw INCREMENT
    dw FROMR
    dw DECREMENT
    dw FROMR
    dw FROMR
    ; Loop back to start
    dw LIT
    dw 56
    dw NEGATE
    dw BRANCH

; ( addr len -- value valid )
; Parse the string $addr $len as a number literal
forthword "PARSE_LIT", 9, PARSE_LIT
    ; Push negative flag
    dw LIT
    dw 0
    dw TOR
    ; Get first character of literal
    dw OVER
    dw LOADC
    ; Is is - (for a negative literal)
    dw DUP
    dw LIT
    dw '-'
    dw EQEQ
    dw LIT
    dw 0
    dw LIT
    dw 12
    dw SELECT
    dw BRANCH
    ; Drop old first character
    dw DROP
    ; Set negative flag
    dw FROMR
    dw DROP
    dw LIT
    dw 0xffff
    dw TOR
    ; Cut off leading -
    dw TOR
    dw INCREMENT
    dw FROMR
    dw DECREMENT
    ; Get new first character
    dw OVER
    dw LOADC
    ; Is it x (for a hex literal)
    dw DUP
    dw LIT
    dw 'x'
    dw EQEQ
    dw LIT
    dw 0
    dw LIT
    dw 5
    dw SELECT
    dw BRANCH
    ; Set base to 16
    dw LIT
    dw 16
    dw LIT
    dw 20
    dw BRANCH
    ; Is it b (for a binary literal)
    dw DUP
    dw LIT
    dw 'b'
    dw EQEQ
    dw LIT
    dw 0
    dw LIT
    dw 5
    dw SELECT
    dw BRANCH
    ; Set base to 2
    dw LIT
    dw 2
    dw LIT
    dw 5
    dw BRANCH
    ; Not binary or hex, decimal
    ; Set base to 10
    dw LIT
    dw 10
    dw LIT
    dw 8
    dw BRANCH
    ; addr len first base
    ; Remove base indicator from literal
    dw TOR
    dw TOR
    dw TOR
    dw INCREMENT
    dw FROMR
    dw DECREMENT
    dw FROMR
    dw FROMR
    ; Drop first char of literal (used for determining base)
    dw TOR
    dw DROP
    dw FROMR
    ; Actually parse the literal
    dw PARSE_NUM
    ; Handle negative literals
    dw SWAP
    dw FROMR
    dw SWAP
    dw DUP
    dw NEGATE
    dw SWAP
    dw SELECT
    dw SWAP
    dw EXIT

; ( addr len addr len -- equal )
; Compare two strings for equality
forthword "STREQ", 5, STREQ
    ; Compare lengths
    dw LIT
    dw 3
    dw PICK
    dw EQEQ
    dw LIT
    dw 5
    dw LIT
    dw 0
    dw SELECT
    dw BRANCH
    ; Not equal, return false
    dw TWODROP
    dw DROP
    dw LIT
    dw 0
    dw EXIT
    ; Lengths are equal, compare characters
    ; Push index
    dw LIT
    dw 0
    ; Loop start
    ; ( addr_1 len addr_2 index )
    ; Check for end
    dw DUP
    dw LIT
    dw 4
    dw PICK
    dw EQEQ
    dw LIT
    dw 0
    dw LIT
    dw 5
    dw SELECT
    dw BRANCH
    ; Index = length, equal, return true
    dw TWODROP
    dw TWODROP
    dw LIT
    dw 0xffff
    dw EXIT
    ; Character to compare
    ; Get char from string 1
    dw DUP
    dw LIT
    dw 5
    dw PICK
    dw PLUS
    dw LOADC
    ; Get char from string 2
    dw OVER
    dw LIT
    dw 4
    dw PICK
    dw PLUS
    dw LOADC
    ; Compare
    dw EQEQ
    dw LIT
    dw 5
    dw LIT
    dw 0
    dw SELECT
    dw BRANCH
    ; Not equal, return false
    dw TWODROP
    dw TWODROP
    dw LIT
    dw 0
    dw EXIT
    ; Chars are equal, next
    ; Increment index
    dw INCREMENT
    ; Loop
    dw LIT
    dw 45
    dw NEGATE
    dw BRANCH

; ( addr len -- entry | addr len 0 )
; Attempt to look up the dictionary entry for a word. Returns a (non-zero) entry
; address if found, or the input string and zero if not found
forthword "FIND", 4, FIND
    ; Push LATEST (starting entry)
    dw LATEST
    dw LOAD
    ; Loop start
    ; addr len entry
    ; Check for not found
    dw DUP
    dw LIT
    dw 1
    dw LIT
    dw 0
    dw SELECT
    dw BRANCH
    ; Not found
    dw EXIT
    ; Get entry name string data
    dw DUP
    dw LIT
    dw 4
    dw PLUS         ; Address
    dw OVER
    dw INCREMENT
    dw INCREMENT
    dw LOAD
    dw LIT
    dw F_LENMASK
    dw FAND         ; Length
    ; Compare
    dw LIT
    dw 5
    dw PICK
    dw LIT
    dw 5
    dw PICK
    dw STREQ
    dw LIT
    dw 5
    dw LIT
    dw 0
    dw SELECT
    dw BRANCH
    ; Not equal, next entry
    dw LOAD
    ; Loop
    dw LIT
    dw 37
    dw NEGATE
    dw BRANCH
    ; Equal, return
    dw TOR
    dw TWODROP
    dw FROMR
    dw EXIT

; ( entry -- codeword )
; Convert a dictionary entry pointer to the corresponding codeword address
forthword ">CFA", 4, TOCFA
    ; Increment to length field
    dw INCREMENT
    dw INCREMENT
    ; Get length
    dw DUP
    dw LOAD
    ; Mask flags
    dw LIT
    dw 0x7fff
    dw FAND
    ; Advance to end of name
    dw PLUS
    ; Advance to codeword pointer and return
    dw INCREMENT
    dw INCREMENT
    dw EXIT

; ( codeword -- )
; Append $codeword to dictionary memory
forthword "COMMA", 5, COMMA
    ; Get address of next free word
    dw HERE
    dw LOAD
    ; Update HERE
    dw DUP
    dw INCREMENT
    dw INCREMENT
    dw HERE
    dw STORE
    ; Store codeword and return
    dw STORE
    dw EXIT

; ( -!- )
; ( Switch to immidiate mode )
forthword "[", 0x8001, ENDC
    dw LIT
    dw 0
    dw STATE
    dw STORE
    dw EXIT

; ( -- )
; ( Switch to compile mode )
forthword "]", 1, BEGINC
    dw LIT
    dw 0xffff
    dw STATE
    dw STORE
    dw EXIT

; ( addr length -- )
; ( Create a dictionary entry with the name $adder $len )
forthword "CREATE", 6, CREATE
    ; ( Get word start address )
    dw HERE
    dw LOAD
    dw TOR
    ; ( Write link pointer )
    dw LATEST
    dw LOAD
    dw COMMA
    ; ( Name length )
    dw DUP
    dw COMMA
    ; ( Copy name )
    dw DUP
    dw TOR
    dw HERE
    dw LOAD
    dw COPY
    dw FROMR
    dw HERE
    dw LOAD
    dw PLUS
    dw HERE
    dw STORE
    ; ( Update LATEST )
    dw FROMR
    dw LATEST
    dw STORE
    ; ( Return )
    dw EXIT

; ( -- )
; ( Begin a word definition )
forthword ":", 1, COLON
    ; ( Get name of word to define )
    dw FWORD
    ; ( Create dictionary header )
    dw CREATE
    ; ( Append codeword )
    dw LIT
    dw DOCOL
    dw COMMA
    ; ( Enter compile mode )
    dw BEGINC
    ; ( Return )
    dw EXIT

; ( -!- )
; ( End a word definition )
forthword ";", 0x8001, SEMICOLON
    ; ( Add return from word )
    dw LIT
    dw EXIT
    dw COMMA
    ; ( Enter immidiate mode )
    dw ENDC
    ; ( Return )
    dw EXIT

; ( -- xt )
; ( Get the execution token of the next word )
forthword "`", 0x8001, TICK
    dw FWORD
    dw FIND
    dw TOCFA
    dw STATE
    dw LOAD
    dw LIT
    dw 0
    dw LIT
    dw 4
    dw SELECT
    dw BRANCH
        dw LIT
        dw LIT
        dw COMMA
        dw COMMA
    dw EXIT

; ( -!- )
; ( Toggle the immidiate flag of the most recent entry )
forthword "IMMIDIATE", 0x8009, IMMIDIATE
    dw LATEST
    dw LOAD
    dw INCREMENT
    dw INCREMENT
    dw DUP
    dw LOAD
    dw LIT
    dw 0x8000
    dw FXOR
    dw SWAP
    dw STORE
    dw EXIT

; : [COMPILE] IMMIDIATE WORD FIND >CFA COMMA ; : IF IMMIDIATE ` LIT COMMA 0 COMMA ` LIT COMMA HERE @ 0 COMMA ` ?: COMMA ` BRANCH COMMA ; : THEN IMMIDIATE DUP HERE @ SWAP - SHR 3 - SWAP ! ; : ELSE IMMIDIATE ` LIT COMMA HERE @ 0 COMMA ` NOOP COMMA ` BRANCH COMMA SWAP [COMPILE] THEN ; : FIB DUP IF 1- DUP IF DUP FIB SWAP 1- FIB + ELSE DROP 1 THEN THEN ;

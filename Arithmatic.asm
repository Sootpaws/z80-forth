; <<< Arithmatic and Logic >>>
; ( a b -- a+b )
; Add the top two values on the stack
asmword "+", 1, PLUS
    pop  hl                 ; Get operands
    pop  bc
    add  hl,bc              ; Perform addition
    push hl                 ; Push output
    NEXT

; ( a b -- a-b )
; Subtract the top two values on the stack
asmword "-", 1, MINUS
    pop  bc                 ; Get operands
    pop  hl
    or   a                  ; Clear carry
    sbc  hl,bc              ; Perform subtraction
    push hl                 ; Push output
    NEXT

; ( value -- value+1 )
; Increment the top stack value
forthword "1+", 2, INCREMENT
    dw LIT
    dw 1
    dw PLUS
    dw EXIT

; ( value -- value-1 )
; Decrement the top stack value
forthword "1-", 2, DECREMENT
    dw LIT
    dw 1
    dw MINUS
    dw EXIT

; ( value -- -value )
; Negate the top stack value
forthword "0-", 2, NEGATE
    dw LIT
    dw 0
    dw SWAP
    dw MINUS
    dw EXIT

; ( a b -- equal )
; Compare $a and $b for equality
asmword "==", 2, EQEQ
    pop  hl                 ; Get operands
    pop  de
    or   a                  ; Clear carry
    sbc  hl,de              ; Subtract-compare
    ld   bc,0xffff          ;
    jp   Z,.end             ; Skip if equal
    ld   bc,0               ; Push a zero instead
.end:
    push bc                 ; Push the correct output
    NEXT

; ( a -- !a )
; Invert the bits of $a
asmword "NOT", 3, FNOT
    pop  bc                 ; Get operand
    ld   a,c                ; Invert
    cpl
    ld   c,a
    ld   a,b
    cpl
    ld   b,a
    push bc                 ; Put output on stack
    NEXT

; ( a b -- a&b )
; AND the top two values on the stack
asmword "AND", 3, FAND
    pop  hl                 ; Get operands
    pop  bc
    ld   a,h                ; Perform and
    and  a,b
    ld   h,a
    ld   a,l
    and  a,c
    ld   l,a
    push hl                 ; Output result
    NEXT

; ( a b -- a|b )
; OR the top two values on the stack
asmword "OR", 2, FOR
    pop  hl                 ; Get operands
    pop  bc
    ld   a,h                ; Perform or
    or   a,b
    ld   h,a
    ld   a,l
    or   a,c
    ld   l,a
    push hl                 ; Output result
    NEXT

; ( a b -- a^b )
; XOR the top two values on the stack
asmword "XOR", 3, FXOR
    pop  hl                 ; Get operands
    pop  bc
    ld   a,h                ; Perform xor
    xor  a,b
    ld   h,a
    ld   a,l
    xor  a,c
    ld   l,a
    push hl                 ; Output result
    NEXT

; ( v -- shifted )
; Logical right-shift $v (shifts in zero)
asmword "SHR", 3, FSHR
    pop  hl
    srl  h
    rr   l
    push hl
    NEXT

; ( w -- high )
; Extract the high byte of a value
forthword "HBYTE", 5, HBYTE
    dw FSHR
    dw FSHR
    dw FSHR
    dw FSHR
    dw FSHR
    dw FSHR
    dw FSHR
    dw FSHR
    dw EXIT

; ( w -- low )
; Extract the low byte of a value
forthword "LBYTE", 5, LBYTE
    dw LIT
    dw 0xff
    dw FAND
    dw EXIT

; ( sel t f -- t | f )
; Select between t and f based on sel
asmword "?:", 2, SELECT
    pop  hl                 ; Put f in de
    pop  bc                 ; Put t in bc
    pop  de                 ; Put sel in hl
    push hl                 ; Put f back on the stack
    ld   hl,0               ; Zero hl
    or   a                  ; Clear carry
    sbc  hl,de              ; Subtract-compare sel with zero
    jp   Z,.end             ; Push the correct value
    ; True
    pop  hl                 ; Get f back off the stack
    push bc                 ; Condition was false, push t from bc
.end:
    ; If sel was true, we already pushed t, so we're done
    NEXT

; ( v -- negative? )
; Return true if $v is negative
asmword "-?", 2, ISNEGATIVE
    pop  hl                 ; Get value
    ld   de,0               ; Zero hl
    ld   bc,0xffff          ; True return value
    or   a                  ; Clear carry
    sbc  hl,de              ; Subtract-compare value with zero
    jp   M,.end             ; Done if value was negative
    ld   bc,0               ; Not negative, return value should be zero
.end:
    push bc                 ; Push return value
    NEXT

; ( a b signed? -- (signed?_)greater_equal )
; Check whether $a >= $b. $signed? must be 0x0 (unsigned) or 0x8000 (signed)
forthword ">=?", 3, GEQM
    ; Stash signed flag
    dw TOR
    ; Extract sign bits
    dw OVER
    dw LIT
    dw 0x8000
    dw FAND
    dw OVER
    dw LIT
    dw 0x8000
    dw FAND
    ; ( a b a_sign b_sign )
    ; Check for sign difference
    dw OVER
    dw EQEQ
    dw LIT
    dw 0
    dw LIT
    dw 15
    dw SELECT
    dw BRANCH
    ; ( a b a_sign )
    ; Signs are the same
    ; Mask sign bits (shift numbers into positive range)
    dw DROP
    dw TOR
    dw LIT
    dw 0x7fff
    dw FAND
    dw FROMR
    dw LIT
    dw 0x7fff
    dw FAND
    ; Subtract to compare
    dw MINUS
    dw ISNEGATIVE
    dw FNOT
    ; Drop signed flag
    dw FROMR
    dw DROP
    ; And return
    dw EXIT
    ; Signs are different
    ; Drop input values
    dw TOR
    dw TWODROP
    dw FROMR
    ; Restore signed flag
    dw FROMR
    ; Compute result from sign and signed flags
    dw EQEQ
    dw LIT
    dw 0
    dw LIT
    dw 0xffff
    dw SELECT
    dw EXIT

; ( a b -- signed_greater_equal )
; Check whether $a >= $b, interpreted as signed numbers
forthword ">=S", 3, GEQS
    ; Add signed flag
    dw LIT
    dw 0x8000
    ; Compute and return
    dw GEQM
    dw EXIT

; ( a b -- unsigned_greater_equal )
; Check whether $a >= $b, interpred as unsigned numbers
forthword ">=U", 3, GEQU
    ; Add unsigned flag
    dw LIT
    dw 0
    ; Compute and return
    dw GEQM
    dw EXIT

; ( a b -- product )
; Multiply $a and $b, treated as unsigned numbers
forthword "*U", 2, STARU
    dw LIT
    dw 0
    ; ( a b total )
    ; Check for end
    dw OVER
    dw LIT
    dw 4
    dw LIT
    dw 0
    dw SELECT
    dw BRANCH
    ; End of multiply
    dw TOR
    dw TWODROP
    dw FROMR
    dw EXIT
    ; Add a to total
    dw LIT
    dw 3
    dw PICK
    dw PLUS
    ; Decrement B
    dw TOR
    dw DECREMENT
    dw FROMR
    ; Loop
    dw LIT
    dw 22
    dw NEGATE
    dw BRANCH

; ( a b -- quotient modulus )
; Divide $a by $b, treated as unsigned numbers
; Returns both the quotient and modulus
forthword "\\MODU", 5, DIVMODU
    ; Push starting quotient
    dw LIT
    dw 0
    dw TOR
    ; Division loop
    ; ( a b )
    ; Is a >= b?
    dw OVER
    dw OVER
    dw GEQU
    dw LIT
    dw 0
    dw LIT
    dw 11
    dw SELECT
    dw BRANCH
    ; Incrament quotient
    dw FROMR
    dw INCREMENT
    dw TOR
    ; Subtract b from a
    dw DUP
    dw TOR
    dw MINUS
    dw FROMR
    ; Loop back to start
    dw LIT
    dw 20
    dw NEGATE
    dw BRANCH
    ; a < b, division is done
    ; Drop b, no longer needed
    dw DROP
    ; a is the modulus
    ; Restore quotient
    dw FROMR
    ; And return
    dw SWAP
    dw EXIT

; ( a b -- quotient )
; Divide $a by $b, treated as unsigned numbers
; Only returns the quotient
forthword "\\U", 2, DIVU
    dw DIVMODU
    dw DROP
    dw EXIT

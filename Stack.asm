; ( value -- ) TODO: Return stack signature
; Move value from data stack to return stack
asmword ">R", 2, TOR
    pop bc                  ; Get value
    ld  hl,(RSP)            ; Get RSP value
    ld  (hl),c              ; Push value to RSP
    inc hl
    ld  (hl),b
    inc hl
    ld  (RSP),hl            ; Update RSP value
    NEXT

; ( -- value ) TODO: Return stack signature
; Move value from return stack to data stack
asmword "R>", 2, FROMR
    ld   hl,(RSP)           ; Get RSP value
    dec  hl                 ; Pop value from RSP
    ld   b,(hl)
    dec  hl
    ld   c,(hl)
    ld   (RSP),hl           ; Update RSP value
    push bc                 ; Get value
    NEXT

; ( value -- value value )
; Duplicate the top value on the stack
asmword "DUP", 3, DUP
    pop  hl                 ; Get value to duplicate
    push hl                 ; Put it back on the stack
    push hl                 ; Do it again
    NEXT

; ( value -- )
; Remove the top of stack
asmword "DROP", 4, DROP
    pop hl                  ; Get the top of stack and do nothing with it
    NEXT

; ( value value -- )
; Remove the top two stack values
forthword "2DROP", 5, TWODROP
    dw DROP
    dw DROP
    dw EXIT

; ( a b -- b a )
; Swap the top two stack values
asmword "SWAP", 4, SWAP
    pop  bc                 ; Get B
    pop  de                 ; Get A
    push bc                 ; Push B
    push de                 ; Push A
    NEXT

; ( x_*...x_1 n -- x_n )
; Get the $nth value on the stack
forthword "PICK", 4, PICK
    ; Calculate byte offset
    dw DUP
    dw PLUS
    ; Add selection offset to data stack top
    dw DSPLOAD
    dw PLUS
    ; Add correction offset
    dw INCREMENT
    ; Get value and exit
    dw LOAD
    dw EXIT

; ( x _ -- x _ x )
; Get the second value on the stack
forthword "OVER", 4, OVER
    dw LIT
    dw 2
    dw PICK
    dw EXIT

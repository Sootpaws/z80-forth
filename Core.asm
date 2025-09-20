; ( -- )
; Main interpreter loop
forthword "INIT", 4, INIT
cold_start:
    ; Initialize hardware devices
    dw INITHW
    ; Print status
    ; dw STATUS
    ; Print ready message
    dw LIT
    dw m_ready
    dw LIT
    dw 7
    dw TELL
    ; Interpreter loop
    ; Get word to interpret
    dw FWORD
    ; Check if it is defined
    dw FIND
    dw DUP
    dw LIT
    dw 0
    dw LIT
    dw 33
    dw SELECT
    dw BRANCH
    ; Word is defined
    ; Get codeword
    dw DUP
    dw TOCFA
    ; Immidiate?
    dw SWAP
    dw INCREMENT
    dw INCREMENT
    dw LOAD
    dw LIT
    dw 0x8000
    dw FAND
    dw LIT
    dw 8
    dw LIT
    dw 0
    dw SELECT
    dw BRANCH
    ; Compiling?
    dw STATE
    dw LOAD
    dw LIT
    dw 5
    dw LIT
    dw 0
    dw SELECT
    dw BRANCH
    ; Not compiling, execute and loop
    dw EXECUTE
    dw LIT
    dw 37
    dw NEGATE
    dw BRANCH
    ; Compiling, append and loop
    dw COMMA
    dw LIT
    dw 42
    dw NEGATE
    dw BRANCH
    ; Not defined, literal?
    dw DROP
    ; Try to parse
    dw PARSE_LIT
    ; Check for success
    dw LIT
    dw 0
    dw LIT
    dw 20
    dw SELECT
    dw BRANCH
    ; Literal, compiling?
    dw STATE
    dw LOAD
    dw LIT
    dw 4
    dw LIT
    dw 0
    dw SELECT
    dw BRANCH
    ; Not compiling, leave on stack and loop
    dw LIT
    dw 62
    dw NEGATE
    dw BRANCH
    ; Compiling, append with LIT
    dw LIT
    dw LIT
    dw COMMA
    dw COMMA
    dw LIT
    dw 70
    dw NEGATE
    dw BRANCH
    ; Not defined and not literal, print error and loop
    dw DROP
    dw LIT
    dw '?'
    dw EMIT
    dw FSPACE
    dw LIT
    dw 79
    dw NEGATE
    dw BRANCH

; ( -- )
; Completely reset the Forth runtime
asmword "RESET", 5, RESET
    jp reset_forth

; ( -- )
; Reset the stacks and return to a prompt
asmword "QUIT", 4, QUIT
    jp quit_forth

; ( -- )
; Return from the current word
asmword "EXIT", 4, EXIT
    ld  hl,(RSP)            ; Get RSP value
    dec hl
    ld  b,(hl)
    dec hl
    ld  c,(hl)
    ld  (RSP),hl            ; Update RSP
    ld  (FXP),bc            ; Update FXP
    NEXT

; Do nothing
asmword "NOOP", 4, NOOP
    NEXT

; ( offset -- )
; Jump by offset
asmword "BRANCH", 6, BRANCH
    pop bc                  ; Get offset
    sla c                   ; Double offset
    rl  b
    ld  hl,(FXP)            ; Get FXP
    add hl,bc               ; Add offset
    ld  (FXP),hl            ; Update FXP
    NEXT

; ( xt -- )
; Run the word at $xt
asmword "EXECUTE", 7, EXECUTE
exec_start:
    pop hl                  ; Read codeword address into hl
    ld  e,l                 ; Stash codeword address in de
    ld  d,h
    ld  c,(hl)              ; codeword address (hl) -> codeword (bc)
    inc hl
    ld  b,(hl)
    inc hl
    ld  l,c                 ; codeword (bc) -> hl
    ld  h,b
    ; Codeword is in hl
    ; Codeword address is still in de
    jp  (hl)                ; Run word

; TODO: Signature/notes
asmword "LIT", 3, LIT
    READ_INSTR              ; Read next "codeword pointer" into hl
    push hl                 ; Push onto data stack
    NEXT                    ; Next word

; ( -- DSP )
; Get the value of the Data Stack Pointer INCLUDING the value his word pushes
asmword "DSP@", 4, DSPLOAD
    ld   (temp),sp          ; Move the stack pointer into memory
    ld   hl,(temp)          ; Get it back into a register
    dec  hl                 ; Account for the value we are about to push
    push hl                 ; Put the DSP value onto the stack
    NEXT

; ( -- RSP )
; Get the value of the Return Stack Pointer
asmword "RSP@", 4, RSPLOAD
    ld   hl,(RSP)           ; Get RSP value
    push hl                 ; Put it on the stack
    NEXT

; ( -- DSP0 )
; Get the initial value of the Data Stack Pointer
asmword "DSP0", 4, DSPZERO
    ld   hl,c_DSPZERO
    push hl
    NEXT

; ( -- RSP0 )
asmword "RSP0", 4, RSPZERO
    ld   hl,c_RSPZERO
    push hl
    NEXT

; ( -- *HERE )
; Get a pointer to the HERE pointer
asmword "HERE", 4, HERE
    ld   hl,v_HERE
    push hl
    NEXT

; ( -- HERE0 )
; Get the initial value of the HERE pointer
asmword "HERE0", 5, HEREZERO
    ld   hl,c_HEREZERO
    push hl
    NEXT

; ( -- *LATEST )
; Get a pointer to the LATEST pointer
asmword "LATEST", 6, LATEST
    ld   hl,v_LATEST
    push hl
    NEXT

; ( -- *STATE )
; Get a pointer to the STATE variable
asmword "STATE", 5, STATE
    ld   hl,v_STATE
    push hl
    NEXT

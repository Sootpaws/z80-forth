; ( addr -- value )
; Read the value at an address
asmword "@", 1, LOAD
    pop hl                  ; Get address to read
    ld  c,(hl)              ; Perform read
    inc hl
    ld  b,(hl)
    push bc                 ; Push value back to stack
    NEXT

; ( addr -- byte )
; Read the byte at an address
forthword "@C", 2, LOADC
    dw LOAD
    dw LBYTE
    dw EXIT

; ( value addr -- )
; Write a value to an address
asmword "!", 1, STORE
    pop hl                  ; Get address to write
    pop bc                  ; Get value to write
    ld  (hl),c              ; Perform write
    inc hl
    ld  (hl),b
    NEXT

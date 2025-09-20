; <<< Forth Interpreter >>>
READ_INSTR macro
    ; Overwrites bc, de, and hl
    ; FXP -> FPX value -> codeword address -> codeword
    ld  hl,(FXP)            ; FXP (const) -> FXP value (hl)
    ld  c,(hl)              ; FXP value (hl) -> codeword address (bc)
    inc hl
    ld  b,(hl)
    inc hl
    ld  (FXP),hl            ; Update FXP
    ld  l,c                 ; codeword address (bc) -> hl
    ld  h,b
endm

NEXT macro
    READ_INSTR              ; Read codeword into hl
    ld  e,c                 ; Stash codeword address in de
    ld  d,b
    ld  c,(hl)              ; codeword address (hl) -> codeword (bc)
    inc hl
    ld  b,(hl)
    inc hl
    ld  l,c                 ; codeword (bc) -> hl
    ld  h,b
    ; Codeword is in hl
    ; Codeword address is still in de
    jp  (hl)                ; Run word
endm

; <<< Initialization >>>
    .org 0x0000             ; Boot ROM starts at address 0
entry:
    di                      ; Disable interrupts
    im  2                   ; Set interrupt mode (vectored)
    ld  a,high int_vec_base         ; Set vector table base
    ld  i,a
init_crtc:
    ; Initialize the CRTC
    ld  bc,0x0ffc           ; Count, CRTC address register
    ld  hl,crtc_setup_table+crtc_setup_len-1    ; Index into table
.loop:
    ld  a,(hl)              ; Fetch byte from table
    out (c),b               ; CRTC address register
    out (0xfd),a            ; CRTC data register
    dec hl                  ; Next entry
    dec b
    jp  p,.loop
setup_screen:
    ; Map vram
    ld  a,0x80
    out (0xff),a
    ; Clear screen
    ld  hl,VBASE
    ld  bc,VSIZE
.loop:
    ld  (hl),0x20
    cpi
    jp  pe,.loop
reset_forth:
    ld hl,0                 ; Initialize cursor position
    ld (v_CURSOR),hl
    ld hl,c_HEREZERO        ; Initialize HERE pointer
    ld (v_HERE),hl
    ld hl,c_LATESTZERO      ; Initialize LATEST
    ld (v_LATEST),hl
    ld hl,c_IBUFS
    ld (v_IBUFR),hl         ; Keyboard input buffer read pointer
    ld hl,c_IBUFS
    ld (v_IBUFW),hl         ; Keyboard input buffer write pointer
    ld hl,c_SBUFS
    ld (v_SBUFR),hl         ; Serial buffer read pointer
    ld hl,c_SBUFS
    ld (v_SBUFW),hl         ; Serial buffer write pointer
    ei                      ; Enable interrupts now that input buffer is ready
quit_forth:
    ld hl,cold_start        ; Reset FXP
    ld (FXP),hl
    ld hl,c_RSPZERO         ; Reset RSP
    ld (RSP),hl
    ld hl,c_DSPZERO         ; Reset DSP
    ld sp,hl
    ld hl,0                 ; Reset STATE
    ld (v_STATE),hl
    NEXT                    ; And run!

; Keyboard interrupt handler
int_kbd:
    push af
    push hl
    push bc
    in   a,(0xfc)           ; Read character from keyboard
    ld   hl,(v_IBUFW)       ; Get location to write it to
    ld   (hl),a             ; Write character to buffer
    inc  hl                 ; Move to next buffer location
    or   a                  ; Clear carry
    ld   b,h
    ld   c,l
    ld   hl,c_IBUFE         ; Buffe end
    sbc  hl,bc              ; End reached?
    jp   NZ,.done
    ld   bc,c_IBUFS         ; Wrap
.done
    ld   (v_IBUFW),bc       ; Update buffer write pointer
    pop  bc
    pop  hl
    pop  af
int_null:
    ei
    reti

int_noth:
    jp int_noth

; Serial interrupt handler
int_sio_b_rx:
    push af
    push hl
    push bc
    in   a,(0xf5)           ; Read character from serial port
    ld   hl,(v_SBUFW)       ; Get location to write it to
    ld   (hl),a             ; Write character to buffer
    inc  hl                 ; Move to next buffer location
    or   a                  ; Clear carry
    ld   b,h
    ld   c,l
    ld   hl,c_SBUFE         ; Buffer end
    sbc  hl,bc              ; End reached?
    jp   NZ,.done
    ld   bc,c_SBUFS         ; Wrap
.done:
    ld   (v_SBUFW),bc       ; Update buffer write pointer
    pop  bc
    pop  hl
    pop  af
    ei
    reti

; <<< Forth Interpreter >>>
DOCOL:
    ; Codeword address is in de
    ld  hl,(RSP)            ; Get RSP value
    ld  bc,(FXP)            ; Get old FXP
    ld  a,c                 ; Write old FXP to return stack
    ld  (hl),a
    inc hl
    ld  a,b
    ld  (hl),a
    inc hl
    ld  (RSP),hl            ; Update RSP
    inc de                  ; Increment codeword adress to
    inc de                  ; first data word
    ld  (FXP),de            ; Point FXP there
    NEXT                    ; Run it

; <<< Word Definition Helpers >>>
F_IMMID   equ 0x8000
F_HIDDEN  equ 0x4000
F_LENMASK equ 0x7fff        ; The hidden flag is "part" of the length, STREQ
                            ; will check the lenghts are equal before the actual
                            ; characters are compared. This gets us HIDDEN for
                            ; free!

link defl 0

header macro name, nlaf, label
    ; Link to previous dictionary entry
    dw link
    link defl $-2
    ; Name length and flags
    dw nlaf
    ; Name
    ascii "name"
label`:
endm

asmword macro name, nlaf, label
    ; Create dictionary header
    header "name", nlaf, label
    ; Codeword
    dw label`_code
label`_code:
endm

forthword macro name, nlaf, label
    ; Create dictionary header
    header "name", nlaf, label
    ; Codeword
    dw DOCOL
endm

include Core.asm
include Hardware.asm
include Memory.asm
include Stack.asm
include Arithmatic.asm
include LL_IO.asm
include HL_IO.asm
include Disk.asm
include Dictionary.asm
include Utils.asm

c_LATESTZERO equ link

; CRTC Control
; https://github.com/misterblack1/trs80-diagnosticrom/blob/main/inc/trs80m2con.asm
VBASE equ 0xF800    ; Video memory base address
VSIZE equ 0x0800    ; Video memory size
VLINE equ 80        ; Column count
crtc_setup_table:
    db 0x63			; $0: Horizontal Total = 99
    db 0x50			; $1: Horizontal Displayed = 80
    db 0x55			; $2: H Sync Position = 85
    db 0x08			; $3: Sync Width = 8
    db 0x19			; $4: Vertical Total = 25
    db 0x00			; $5: V Total Adjust = 0
    db 0x18			; $6: Vertical Displayed = 24
    db 0x18			; $7: Vertical Sync Position = 24
    db 0x00			; $8: Interlace Mode and Skew = 0
    db 0x09			; $9: Max Scan Line Address = 9
    db 01100001b	; $A: Cursor Start = 5 (b6:blink on, b5=blink period ct)
    db 0x09			; $B: Cursor End = 9
    db 0x00			; $C: Start Address H = 0
    db 0x00			; $D: Start Address L = 0
    db 0            ; $E: Cursor position high
    db 0            ; $F: Cursor position low
crtc_setup_len equ $-crtc_setup_table

; Digit table
digits: ascii "0123456789abcdef"

; Messages
m_ready:      ascii "Ready.",0xff                               ;  7
status_1:     ascii "TRS-80 Forth [Boot ROM]",0xff,"DSP: "      ; 29
status_2:     ascii 0xff,"RSP: "                                ;  6
status_3:     ascii 0xff,"HERE: "                               ;  7
status_4:     ascii 0xff,"Words: "                              ;  8
status_depth: ascii "depth "                                    ;  6

; <<< Constant Data >>>
; Interrupt vector table
int_vec_table_pad:
    defs low (0x100 - low int_vec_table_pad)
int_vec_base:
    dw int_null         ; Random interrupt on startup for some reason
    dw int_noth         ; Unused
    dw int_noth         ; Unused
    dw int_noth         ; Unused
    dw int_noth         ; CRTC channel 0
    dw int_noth         ; CRTC channel 1
    dw int_noth         ; CRTC channel 2
    dw int_kbd          ; CRTC channel 3
int_vec_sio:
    dw int_noth         ; Serial B buffer empty
    dw int_noth         ; Serial B external/stautus change
    dw int_sio_b_rx     ; Serial B rx
    dw int_noth         ; Serial B error
    dw int_noth         ; Serial A buffer empty
    dw int_noth         ; Serial A external/status change
    dw int_noth         ; Serial A rx
    dw int_noth         ; Serial A error

; <<< Static Variables >>>
; TODO: Put directly after ROM end
FXP        equ 0x4000       ; Forth eXecution Pointer
RSP        equ 0x4002       ; Return Stack Pointer
v_CURSOR   equ 0x4004       ; Cursor index
temp       equ 0x4006       ; Temporary memory location
v_HERE     equ 0x4008       ; Free memory pointer
v_LATEST   equ 0x400a       ; Latest dictionary entry pointer
v_STATE    equ 0x400c       ; Immidate/compiled mode selector
v_IBUFR    equ 0x400e       ; Keyboard buffer read pointer
v_IBUFW    equ 0x4010       ; Keyboard buffer write pointer
v_SBUFR    equ 0x4012       ; Serial buffer read pointer
v_SBUFW    equ 0x4014       ; Serial buffer write pointer

; <<< Static Allocations >>>
c_IBUFS    equ 0x4016       ; Keyboard input buffer
c_IBUFE    equ 0x4116
c_SBUFS    equ 0x4116       ; Serial input buffer
c_SBUFE    equ 0x4216
c_WBUF     equ 0x4216       ; Read word buffer
c_DBUF     equ 0x4316       ; Disk sector buffer
c_RSPZERO  equ 0x4416       ; RSP initial value
c_HEREZERO equ 0x6000       ; HERE initial value
; TODO: Put at top of RAM
c_DSPZERO  equ 0x8000       ; DSP initial value

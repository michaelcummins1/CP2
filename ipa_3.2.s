; CS 274
; IPA 3.2
;
; @author: Michael Cummins
; @purpose: Tracking how many decks exist, tracking available and used cards, 
;           and choosing individual cards at random.

x_0: dw 0x1563   ; current val, init as seed (x_0)
a: dw 0x05       ; multiplier (a)
m: dw 0x315d     ; large prime (m)
x_k: dw 0x00     ; current iteration
decks: db 0x02   ; stores number of decks used (using 3 since it is the max)
curr: db [0x00, 0x04]  ; stores current cards
cards: db [0x00, 0x34] ; stores how many times cards are used

def _lehmer_algo {
    ;compute
    mul bx      ; ax * bx
    div cx      ; ax mod cx, result in dx
    mov ax, dx
    mov word x_k, dx
    inc si
    mov bx, 52
    div bx      ; ax mod bx, result in dx
    ret
}

start:
    mov ax, word x_0    ; load seed
    mov bx, word a      ; load regs bx, cx
    mov cx, word m
    mul bx              ; ax * bx
    div cx              ; ax mod cx, result in dx
    mov ax, dx
    mov word x_k, dx
    
_loop_select:
    cmp di, 0x04        ; loop to select 4 cards
    je _exit_loop
    call _lehmer_algo   ; compute random number
    mov si, OFFSET cards ; load array of used cards
    add si, dx
    mov al, byte[si]    ; move number of uses into al
    mov bl, byte decks
    cmp al, bl        ; compare to see if it has been used already
    jge _loop_select  ; reselect if used too many times
    inc al            ; increment number of uses
    mov byte[si], al
    mov si, OFFSET curr
    inc si
    add si, di
    mov word[si], dx  ; load the current card into the 4 cards in play
    inc di
    jmp _loop_select
    
_exit_loop:

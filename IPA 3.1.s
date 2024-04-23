; CS 274
; IPA 3.1
;
; @author: Isabelle Son
; @purpose: Creating the framework for representing cards, bets and wins on screen

cards:
    ; Hearts 1-13
    db 0x01 db 0x02 db 0x03 db 0x04 db 0x05 db 0x06 db 0x07 
    db 0x08 db 0x09 db 0x0a db 0x0b db 0x0c db 0x0d 
    
    ; Spades 14-26
    db 0x0e db 0x0f db 0x10 db 0x11 db 0x12 db 0x13 db 0x14 
    db 0x15 db 0x16 db 0x17 db 0x18 db 0x19 db 0x1a 
    
    ; Diamonds 27-39
    db 0x1b db 0x1c db 0x1d db 0x1e db 0x1f db 0x20 db 0x21 
    db 0x22 db 0x23 db 0x24 db 0x25 db 0x26 db 0x27 
    
    ; Clubs 40-52
    db 0x28 db 0x29 db 0x2a db 0x2b db 0x2c db 0x2d db 0x2e 
    db 0x2f db 0x30 db 0x31 db 0x32 db 0x33 db 0x34
    
bet_prompt: db "How much would you like bet?"
invalid_bet: db "Invalid bet!"
player_money: db "Your money: $"
comp_money: db "Computer's money: $0"   ; implement later
player_wins: db "Player wins: 0"    ; implement later
comp_wins: db "Computer wins: 0"    ; implement later

player_bet: dw 0
comp_bet: dw 0        ; implement later

player_num_wins: db 0      ; implement later
comp_num_wins: db 0        ; implement later

buffer:
    ; create a buffer for input
    db 0xff     ; maximum value to read
    db 0x00     ; actual value read after INT
    db [0x00, 0x04]     ; buffer of the right size

player_bet_to_print: db [0x00, 0x0a]

cards_to_print: db [0x00, 0xff]

def _char_to_num {
    ; converts all chars to number, moves backwards
    ; cx designated accumulator, si pointer
    mov al, byte [si]
    sub al, 0x30        ; convert to num
    mul bl
    add cx, ax
    mov al, dl
    mul bl
    mov bl, al
    dec si
    ret
}

def _num_to_char {
    ; queues character rep of cards/bet/wins to be printed
    ; ax / cx -> remainder (dx) to char
    ; continue until 0
    div cx
    add dx, 0x30
    push dx
    ret
}

start:
    ; print prompt
    mov ah, 0x13
    mov cx, 0x1c        ; length of string to be printed
    mov bx, 0
    mov es, bx
    mov bp, OFFSET bet_prompt
    mov dl, 0
    int 0x10
    
    ; obtain input from user
    mov ah, 0x0a
    lea dx, word buffer
    int 0x21
    
    mov si, OFFSET buffer
    add si, 2
  
_find_end:
    ; assigns to si the location of the last char
    mov al, byte [si]
    cmp al, 0x00
    je _setup_char_to_num
    inc si
    jmp _find_end
  
_setup_char_to_num:
    dec si      ; assigns si to correct location
    mov di, OFFSET buffer   ; first location of string for cmp
    add di, 7
    cmp si, di
    jge _thousands
    sub di, 5
    mov ax, 0x00
    mov cx, 0           ; accumulator
    mov bl, 0x01        ; multiplier
    mov dl, 0x0a        ; base
    jmp _input
    
_input:
    ; sets up bet input to be workable
    cmp si, di
    jl _check_bet
    call _char_to_num
    jmp _input
    
_thousands:
    ; case if bet is in thousands or greater
    ; checks if bet = 1000
    mov al, byte [di]
    sub al, 0x30
    cmp al, 1
    jne _invalid_bet
    mov word player_bet, 0x3e8
    jmp _cards
    
_check_bet:
    ; checks if bet is valid
    mov word player_bet, cx
    mov si, OFFSET player_bet
    mov ax, word [si]
    cmp ax, 0xa
    jl _invalid_bet
    jmp _cards
    
_invalid_bet:
    ; prints invalid bet
    mov ah, 0x13
    mov cx, 0x0c        ; length of string to be printed
    mov bx, 0
    mov es, bx
    mov bp, OFFSET invalid_bet
    mov dl, 0
    int 0x10
    jmp start
    
_cards:
    ; prepare cards for print
    mov ax, 0x00
    mov si, OFFSET bet_prompt       ; find end of cards, change appropriately
    dec si
    
_card_loop:
    cmp si, OFFSET cards
    jnge _print
    mov al, byte [si]
    ; assign suit
_hearts:
    cmp al, 0x0d
    jg _spades
    mov bx, 0x48        ; "H"
    jmp _end_assign
_spades: 
    cmp al, 0x1a
    jg _diamonds
    mov bx, 0x53        ; "S"
    sub al, 0x0d        ; convert to card value
    jmp _end_assign
_diamonds:
    cmp al, 0x27
    jg _clubs
    mov bx, 0x44        ; "D"
    sub al, 0x1a        ; convert to card value
    jmp _end_assign
_clubs:
    mov bx, 0x43        ; "C"
    sub al, 0x27        ; convert to card value
_end_assign:
    push bx
    mov cx, 0x0a        ; base
    
_num_to_char_loop:
    call _num_to_char
    cmp ax, 0x00
    jg _num_to_char_loop
    
    mov bx, 0x20
    push bx
    dec si
    jmp _card_loop
    
_print:
    mov si, OFFSET cards_to_print
    
_print_loop:
    ; takes from stack and sets up for print
    cmp sp, 0x0000      ; check for empty stack
    jnl _print_stats
    pop ax
    mov word [si], ax
    inc si
    jmp _print_loop
    
_print_stats:
    ; print player money
    mov ah, 0x13
    mov cx, 0x0d        ; length of string to be printed
    mov bx, 0
    mov es, bx
    mov bp, OFFSET player_money
    mov dl, 0
    int 0x10
    mov ax, word player_bet
    mov si, OFFSET player_bet_to_print
    
_bet_to_char_loop:
    call _num_to_char
    cmp ax, 0x00
    jg _bet_to_char_loop
    
_bet_print_loop:
    ; prepares player bet to print
    cmp sp, 0x0000      ; check for empty stack
    jnl _comp_money
    pop ax
    mov word [si], ax
    inc si
    jmp _bet_print_loop
    
    ; print player bet val
    mov ah, 0x13
    mov cx, 0x0a        ; length of string to be printed
    mov bx, 0
    mov es, bx
    mov bp, OFFSET player_bet_to_print
    mov dl, 0
    int 0x10
    
_comp_money:
    ; print computer money
    mov ah, 0x13
    mov cx, 0x14        ; length of string to be printed
    mov bx, 0
    mov es, bx
    mov bp, OFFSET comp_money
    mov dl, 0
    int 0x10

    ; print player wins
    mov ah, 0x13
    mov cx, 0x0e        ; length of string to be printed
    mov bx, 0
    mov es, bx
    mov bp, OFFSET player_wins
    mov dl, 0
    int 0x10

    ; print computer wins
    mov ah, 0x13
    mov cx, 0x10        ; length of string to be printed
    mov bx, 0
    mov es, bx
    mov bp, OFFSET comp_wins
    mov dl, 0
    int 0x10

_print_cards:
    mov ah, 0x13
    mov cx, 0xff        ; length of string to be printed
    mov bx, 0
    mov es, bx
    mov bp, OFFSET cards_to_print
    mov dl, 0
    int 0x10

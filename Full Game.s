; CS 274
; IPA 3.4
;
; @author: Michael Cummins Isabelle Son
; @purpose: Finalize the game

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
    
decks:
    db [0x00, 0x34] ; stores how many times cards are used
    
; holds the card codes (values in cards list)
; assists in printing
player_card_codes:
    db [0x00, 0x07]
    
comp_card_codes:
    db [0x00, 0x07]

fund_prompt: db "What are your funds? (10-1000, only numerical value)"    
bet_prompt: db "How much would you like bet?"
deck_prompt: db "How many decks would you like to use?"
difficulty_prompt: db "Difficulty: 1-Easy, 2-Normal, 3-Hard"
invalid_bet: db "Invalid bet!"
h_s_prompt: db "1-Hit, 0-Stay, or 2-Forfeit?"
continue_prompt: db "Continue? 1-Yes 0-No"
player_cards: db "Player cards: "
comp_cards: db "Computer cards: "
player_money: db "Your money: $"
comp_money: db "Computer's money: $"
player_wins: db "Player wins: "
comp_wins: db "Computer wins: "
final_player_win: db "The player has won the game!"
final_comp_win: db "The computer has won the game."

num_decks: db 0     ; to compare against in card picking

difficulty: db 0    ; 1-Easy, 2-Normal, 3-Hard

x_0: dw 0x1563   ; current val, init as seed (x_0)
a: dw 0x05       ; multiplier (a)
m: dw 0x315d     ; large prime (m)
x_k: dw 0x00     ; current iteration

; total amount
player_funds: dw 0
comp_funds: dw 0

; current turn bet
player_bet: dw 0
comp_bet: dw 0

; accumulated card values
player_card_val: db 0
comp_card_val: db 0

; 1-Hit or 0-Stay or 2-Forfeit
player_h_s: db 0
comp_h_s: db 0

player_num_wins: db 0 
comp_num_wins: db 0

fund_buffer:
    db 0xff     ; maximum value to read
    db 0x00     ; actual value read after INT
    db [0x00, 0x04]     ; buffer of the right size
    
bet_buffer:
    db 0xff     ; maximum value to read
    db 0x00     ; actual value read after INT
    db [0x00, 0x0a]     ; buffer of the right size
    
deck_buffer:
    db 0xff     ; maximum value to read
    db 0x00     ; actual value read after INT
    db [0x00, 0x01]     ; buffer of the right size

difficulty_buffer:
    db 0xff     ; maximum value to read
    db 0x00     ; actual value read after INT
    db [0x00, 0x01]     ; buffer of the right size
    
continue_buffer:
    db 0xff     ; maximum value to read
    db 0x00     ; actual value read after INT
    db [0x00, 0x01]     ; buffer of the right size
    
h_s_buffer:
    db 0xff     ; maximum value to read
    db 0x00     ; actual value read after INT
    db [0x00, 0x01]     ; buffer of the right size

player_wins_to_print: db [0x00, 0x0a]
comp_wins_to_print: db [0x00, 0x0a]
    
player_funds_to_print: db [0x00, 0x0a]
comp_funds_to_print: db [0x00, 0x0a]

player_cards_to_print: db [0x00, 0x15]  ; 21 spaces, can at most be A+2+3+4+5+6 before loss/win
comp_cards_to_print: db [0x00, 0x15]

def _comp_bet {

    ; * how to decide?
    
    ; * conservative - under-bet by 20%
    ; * normal - ret user bet
    ; * aggressive - outmatch bet by 30%
    ret
}

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

def _lehmer_algo {
    ;compute the algorithm for random selection
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
    ; SETUP
    ; Initialize the variables for random selection
    mov ax, word x_0    ; load seed
    mov bx, word a      ; load regs bx, cx
    mov cx, word m
    mul bx              ; ax * bx
    div cx              ; ax mod cx, result in dx
    mov ax, dx
    mov word x_k, dx
    
    ; print prompt for number of decks
    mov ah, 0x13
    mov cx, 0x25        ; length of string to be printed
    mov bx, 0
    mov es, bx
    mov bp, OFFSET deck_prompt
    mov dl, 0
    int 0x10
    
    ; store in deck_buffer
    mov ah, 0x0a
    lea dx, word deck_buffer
    int 0x21
    
    ; subtract 0x30 from val in buffer,
    ; move to num_decks
    mov si, OFFSET deck_buffer
    add si, 0x02
    mov al, byte [si]
    sub al, 0x30
    mov byte num_decks, al
    
_enter_amount:
    ; print prompt for player funds
    mov ah, 0x13
    mov cx, 0x34        ; length of string to be printed
    mov bx, 0
    mov es, bx
    mov bp, OFFSET fund_prompt
    mov dl, 0
    int 0x10
    
    ; obtain user input for funds ($10-$1000) -> buffer
    mov ah, 0x0a
    lea dx, word fund_buffer
    int 0x21
    
    ; set up regs for _char_to_num
    mov si, OFFSET fund_buffer
    add si, 0x05        ; move si to end of funds
    mov di, OFFSET fund_buffer
    add di, 0x02        ; move di to beginning of funds
    mov ax, 0x00        ; reset ax
    mov cx, 0           ; accumulator
    mov bl, 0x01        ; multiplier
    mov dl, 0x0a        ; base
    
_fund_loop:
    cmp si, di
    jl _exit_fund_loop
    call _char_to_num
    jmp _fund_loop
    
_exit_fund_loop:    
    ; bet value now stored in cx
    ; move to player_funds
    mov word player_funds, cx
    
    
    ; * computer risk level?
    
    ; print difficulty prompt
    mov ah, 0x13
    mov cx, 0x24        ; length of string to be printed
    mov bx, 0
    mov es, bx
    mov bp, OFFSET difficulty_prompt
    mov dl, 0
    int 0x10
    
    ; store in difficulty_buffer
    mov ah, 0x0a
    lea dx, word difficulty_buffer
    int 0x21
    
    ; subtract 0x30 from val in buffer,
    ; move to difficulty
    mov si, OFFSET difficulty_buffer
    add si, 0x02
    mov al, byte [si]
    sub al, 0x30
    mov byte difficulty, al
    
    
    ; * based on difficulty, assign value to comp_funds
    ; * easy - 50% of player funds
    ; * normal - 100% of player funds
    ; * hard - 150% of player funds
    
    ; * move val to comp_funds
    
    
_round_loop:
    ; actions performed every round
    ; check funds:
    ; * if comp_funds insufficient, jump to _final_player_win
    ; * if player_funds insufficient, jump to _final_comp_win
    
    ; print bet_prompt and store in buffer
    mov ah, 0x13
    mov cx, 0x1c        ; length of string to be printed
    mov bx, 0
    mov es, bx
    mov bp, OFFSET bet_prompt
    mov dl, 0
    int 0x10
    
    mov ah, 0x0a
    lea dx, word bet_buffer
    int 0x21
    
    ; set up regs for _char_to_num
    mov si, OFFSET bet_buffer
    add si, 0x0b        ; move si to end of bet
    mov di, OFFSET bet_buffer
    add di, 0x02        ; move di to beginning of bet
    mov ax, 0x00        ; reset ax
    mov cx, 0           ; accumulator
    mov bl, 0x01        ; multiplier
    mov dl, 0x0a        ; base
    
_bet_loop:
    cmp si, di
    jl _exit_bet_loop
    call _char_to_num
    jmp _bet_loop
    
_exit_bet_loop:    
    ; bet value now stored in cx
    ; move to player_bet
    mov word player_bet, cx
    
    
    ; check if player_funds > player_bet, 
    ; if not, jump to _invalid_bet, go back to _round_loop
    mov ax, word player_funds
    mov bx, word player_bet
    cmp ax, bx
    jle _invalid_bet
    jmp _valid_bet
    
_invalid_bet:
    mov ah, 0x13
    mov cx, 0xc        ; length of string to be printed
    mov bx, 0
    mov es, bx
    mov bp, OFFSET invalid_bet
    mov dl, 0
    int 0x10
    jmp _round_loop
    
_valid_bet:
    call _comp_bet
    ; * check if comp_funds > comp_bet,
    ; * if not, move all funds to bet
    
    ; * implement random card choosing
    ; * 1 card to player, 1 card to computer
    ; add cards to player_card_codes and comp_card_codes ->
    ; loop will add to respective "to_prints" along with suits
    ; add card values to player_card_val and computer_card_val
    
; set up player card assignment + print
_sp_cards:
    ; prepare cards for print
    mov ax, 0x00
    mov si, OFFSET player_card_codes
    add si, 0x06           ; find end of player_card_codes
    
_sp_card_loop:
    cmp si, OFFSET player_card_codes
    jnge _sp_print
    mov al, byte [si]
    
    ; case: empty char
    cmp al, 0x00
    je _sp_exit_num_to_char_loop
    
    ; assign suit
_sp_hearts:
    cmp al, 0x0d
    jg _sp_spades
    mov bx, 0x48        ; "H"
    jmp _sp_end_assign
_sp_spades: 
    cmp al, 0x1a
    jg _sp_diamonds
    mov bx, 0x53        ; "S"
    sub al, 0x0d        ; convert to card value
    jmp _sp_end_assign
_sp_diamonds:
    cmp al, 0x27
    jg _sp_clubs
    mov bx, 0x44        ; "D"
    sub al, 0x1a        ; convert to card value
    jmp _sp_end_assign
_sp_clubs:
    mov bx, 0x43        ; "C"
    sub al, 0x27        ; convert to card value
_sp_end_assign:
    push bx
    mov cl, byte player_card_val
    add cl, al          ; add current card to total player card sum
    mov byte player_card_val, cl
    mov cx, 0x0a        ; base
    
_sp_num_to_char_loop:
    call _num_to_char
    cmp ax, 0x00
    jg _sp_num_to_char_loop
    
_sp_exit_num_to_char_loop:
    mov bx, 0x20        ; ascii code for ' ' (space)
    push bx
    dec si
    jmp _sp_card_loop
    
_sp_print:
    ; print player_cards
    mov ah, 0x13
    mov cx, 0x0e        ; length of string to be printed
    mov bx, 0
    mov es, bx
    mov bp, OFFSET player_cards
    mov dl, 0
    int 0x10
    
    mov si, OFFSET player_cards_to_print
    
_sp_print_loop:
    ; takes from stack and sets up for print
    cmp sp, 0x0000      ; check for empty stack
    jnl _sp_final_print
    pop ax
    mov word [si], ax
    inc si
    jmp _sp_print_loop
    
_sp_final_print:
    mov ah, 0x13
    mov cx, 0x15        ; length of string to be printed
    mov bx, 0
    mov es, bx
    mov bp, OFFSET player_cards_to_print
    mov dl, 0
    int 0x10
    
    mov si, OFFSET player_cards_to_print
    add si, 0x14        ; end of card list
    
_sp_clear_cards:
    cmp si, OFFSET player_cards_to_print
    jnge _sc_cards
    mov byte [si], 0x00
    jmp _sp_clear_cards
    
    
; set up computer card assignment + print   
_sc_cards:
    ; prepare cards for print
    mov ax, 0x00
    mov si, OFFSET comp_card_codes
    add si, 0x06           ; find end of comp_card_codes
    
_sc_card_loop:
    cmp si, OFFSET comp_card_codes
    jnge _sc_print
    mov al, byte [si]
    
    ; case: empty char
    cmp al, 0x00
    je _sc_exit_num_to_char_loop
    
    ; assign suit
_sc_hearts:
    cmp al, 0x0d
    jg _sc_spades
    mov bx, 0x48        ; "H"
    jmp _sc_end_assign
_sc_spades: 
    cmp al, 0x1a
    jg _sc_diamonds
    mov bx, 0x53        ; "S"
    sub al, 0x0d        ; convert to card value
    jmp _sc_end_assign
_sc_diamonds:
    cmp al, 0x27
    jg _sc_clubs
    mov bx, 0x44        ; "D"
    sub al, 0x1a        ; convert to card value
    jmp _sc_end_assign
_sc_clubs:
    mov bx, 0x43        ; "C"
    sub al, 0x27        ; convert to card value
_sc_end_assign:
    push bx
    mov cl, byte comp_card_val
    add cl, al          ; add current card to total player card sum
    mov byte comp_card_val, cl
    mov cx, 0x0a        ; base
    
_sc_num_to_char_loop:
    call _num_to_char
    cmp ax, 0x00
    jg _sc_num_to_char_loop
    
_sc_exit_num_to_char_loop:
    mov bx, 0x20        ; ascii code for ' ' (space)
    push bx
    dec si
    jmp _sc_card_loop
    
_sc_print:
    ; print comp_cards
    mov ah, 0x13
    mov cx, 0x10        ; length of string to be printed
    mov bx, 0
    mov es, bx
    mov bp, OFFSET comp_cards
    mov dl, 0
    int 0x10
    
    mov si, OFFSET comp_cards_to_print
    
_sc_print_loop:
    ; takes from stack and sets up for print
    cmp sp, 0x0000      ; check for empty stack
    jnl _sc_final_print
    pop ax
    mov word [si], ax
    inc si
    jmp _sc_print_loop
    
_sc_final_print:
    mov ah, 0x13
    mov cx, 0x15        ; length of string to be printed
    mov bx, 0
    mov es, bx
    mov bp, OFFSET comp_cards_to_print
    mov dl, 0
    int 0x10
    
    mov si, OFFSET comp_cards_to_print
    add si, 0x14        ; end of card list
    
_sc_clear_cards:
    cmp si, OFFSET comp_cards_to_print
    jnge _turn_loop
    mov byte [si], 0x00
    jmp _sc_clear_cards
    
    
_turn_loop:
    ; actual "get to 21"
_loop_select:
    ; At the end dx stored the numerical equivalent of the card
    cmp di, 0x04        ; loop to select 4 cards
    je _player_turn
    call _lehmer_algo   ; compute random number
    mov si, OFFSET decks ; load array of used cards
    add si, dx
    mov al, byte[si]    ; move number of uses into al
    mov bl, byte num_decks
    cmp al, bl        ; compare to see if it has been used already
    jge _loop_select  ; reselect if used too many times
    inc al            ; increment number of uses
    mov byte[si], al
    ; *need to change below to put the cards where they need to be
    inc di
    jmp _loop_select
    
_player_turn:
    ; ask player to hit, stay, or forfeit
    mov ah, 0x13
    mov cx, 0x1c        ; length of string to be printed
    mov bx, 0
    mov es, bx
    mov bp, OFFSET h_s_prompt
    mov dl, 0
    int 0x10
    
    ; store in h_s_buffer
    mov ah, 0x0a
    lea dx, word h_s_buffer
    int 0x21
    
    ; subtract 0x30 from val in h_s_buffer,
    ; move to player_h_s
    mov si, OFFSET h_s_buffer
    add si, 0x02
    mov al, byte [si]
    sub al, 0x30
    mov byte player_h_s, al
    
    ; * jump to _computer_turn if 0
    ; * jump to _exit_turn if 2
    ; * add card to players card
    ; * add value to player_card_val
    ; * add to player_cards_to_print
    
    ; print current cards
; player card assignment + print
_p_cards:
    ; prepare cards for print
    mov ax, 0x00
    mov si, OFFSET player_card_codes
    add si, 0x06           ; find end of player_card_codes
    
_p_card_loop:
    cmp si, OFFSET player_card_codes
    jnge _p_print
    mov al, byte [si]
    
    ; case: empty char
    cmp al, 0x00
    je _p_exit_num_to_char_loop
    
    ; assign suit
_p_hearts:
    cmp al, 0x0d
    jg _p_spades
    mov bx, 0x48        ; "H"
    jmp _p_end_assign
_p_spades: 
    cmp al, 0x1a
    jg _p_diamonds
    mov bx, 0x53        ; "S"
    sub al, 0x0d        ; convert to card value
    jmp _p_end_assign
_p_diamonds:
    cmp al, 0x27
    jg _p_clubs
    mov bx, 0x44        ; "D"
    sub al, 0x1a        ; convert to card value
    jmp _p_end_assign
_p_clubs:
    mov bx, 0x43        ; "C"
    sub al, 0x27        ; convert to card value
_p_end_assign:
    push bx
    mov cl, byte player_card_val
    add cl, al          ; add current card to total player card sum
    mov byte player_card_val, cl
    mov cx, 0x0a        ; base
    
_p_num_to_char_loop:
    call _num_to_char
    cmp ax, 0x00
    jg _p_num_to_char_loop
    
_p_exit_num_to_char_loop:
    mov bx, 0x20        ; ascii code for ' ' (space)
    push bx
    dec si
    jmp _p_card_loop
    
_p_print:
    ; print player_cards
    mov ah, 0x13
    mov cx, 0x0e        ; length of string to be printed
    mov bx, 0
    mov es, bx
    mov bp, OFFSET player_cards
    mov dl, 0
    int 0x10
    
    mov si, OFFSET player_cards_to_print
    
_p_print_loop:
    ; takes from stack and sets up for print
    cmp sp, 0x0000      ; check for empty stack
    jnl _p_final_print
    pop ax
    mov word [si], ax
    inc si
    jmp _p_print_loop  
    
_p_final_print:
    mov ah, 0x13
    mov cx, 0x15        ; length of string to be printed
    mov bx, 0
    mov es, bx
    mov bp, OFFSET player_cards_to_print
    mov dl, 0
    int 0x10
    
    mov si, OFFSET player_cards_to_print
    add si, 0x14        ; end of card list
    
_p_clear_cards:
    cmp si, OFFSET player_cards_to_print
    jnge _p_exit_clear_cards
    mov byte [si], 0x00
    jmp _p_clear_cards
    
_p_exit_clear_cards:
    ; if player_card_val > 21, jump to _comp_win
    ; if player_card_val = 21, jump to _player_win
    cmp byte player_card_val, 0x15
    jg _comp_win
    je _player_win
    
_computer_turn:
    mov al, byte player_card_val
    mov bl, byte comp_card_val
    sub al, bl
    cmp al, 10
    jge _fold
    mov bl, byte comp_card_val
    mov al, 0x15
    sub al, bl
    cmp al, 0x05
    jl _stand
    jmp _add
    
_stand:
    jmp _c_cards
_fold:
    jmp _player_win
_add:
    ; * Redo lehmer algorithm to compute another card for the computer
    call _lehmer_algo   ; compute random number
    mov si, OFFSET decks ; load array of used cards
    add si, dx
    mov al, byte[si]    ; move number of uses into al
    mov bl, byte num_decks
    cmp al, bl        ; compare to see if it has been used already
    jge _add          ; reselect if used too many times
    inc al            ; increment number of uses
    mov byte[si], al
    
    ; print current cards
; computer card assignment + print   
_c_cards:
    ; prepare cards for print
    mov ax, 0x00
    mov si, OFFSET comp_card_codes
    add si, 0x06           ; find end of comp_card_codes
    
_c_card_loop:
    cmp si, OFFSET comp_card_codes
    jnge _c_print
    mov al, byte [si]
    
    ; case: empty char
    cmp al, 0x00
    je _c_exit_num_to_char_loop
    
    ; assign suit
_c_hearts:
    cmp al, 0x0d
    jg _c_spades
    mov bx, 0x48        ; "H"
    jmp _c_end_assign
_c_spades: 
    cmp al, 0x1a
    jg _c_diamonds
    mov bx, 0x53        ; "S"
    sub al, 0x0d        ; convert to card value
    jmp _c_end_assign
_c_diamonds:
    cmp al, 0x27
    jg _c_clubs
    mov bx, 0x44        ; "D"
    sub al, 0x1a        ; convert to card value
    jmp _c_end_assign
_c_clubs:
    mov bx, 0x43        ; "C"
    sub al, 0x27        ; convert to card value
_c_end_assign:
    push bx
    mov cl, byte comp_card_val
    add cl, al          ; add current card to total player card sum
    mov byte comp_card_val, cl
    mov cx, 0x0a        ; base
    
_c_num_to_char_loop:
    call _num_to_char
    cmp ax, 0x00
    jg _c_num_to_char_loop
    
_c_exit_num_to_char_loop:
    mov bx, 0x20        ; ascii code for ' ' (space)
    push bx
    dec si
    jmp _c_card_loop
    
_c_print:
    ; print comp_cards
    mov ah, 0x13
    mov cx, 0x10        ; length of string to be printed
    mov bx, 0
    mov es, bx
    mov bp, OFFSET comp_cards
    mov dl, 0
    int 0x10
    
    mov si, OFFSET comp_cards_to_print
    
_c_print_loop:
    ; takes from stack and sets up for print
    cmp sp, 0x0000      ; check for empty stack
    jnl _c_final_print
    pop ax
    mov word [si], ax
    inc si
    jmp _c_print_loop
    
_c_final_print:
    mov ah, 0x13
    mov cx, 0x15        ; length of string to be printed
    mov bx, 0
    mov es, bx
    mov bp, OFFSET comp_cards_to_print
    mov dl, 0
    int 0x10
 
    mov si, OFFSET comp_cards_to_print
    add si, 0x14        ; end of card list
    
_c_clear_cards:
    cmp si, OFFSET comp_cards_to_print
    jnge _c_exit_clear_cards
    mov byte [si], 0x00
    jmp _c_clear_cards
    
_c_exit_clear_cards:
    ; * if comp_card_val > 21, jump to _player_win
    ; * if comp_card_val = 21, jump to _comp_win
    ; * jump to _turn_loop
    
__check_both_stay:
    ; * if both player_h_s and comp_h_s are 0, jump to _cmp_vals
    ; * jump to _turn_loop
    

_cmp_vals:
    ; * if player_card_val > comp_card_val, jump to _player_win
    ; * if comp_card_val > player_card_val, jump to _comp_win
    ; * if equal, jump to _exit_turn
    

_player_win:
    ; * increase player_wins
    ; * subtract comp_bet from comp_funds
    ; * add comp_bet to player_funds
    ; * jump to _exit_turn
    
_comp_win:
    ; * increase comp_wins
    ; * subtract player_bet from player_funds
    ; * add player_bet to comp_funds
    ; * jump to _exit_turn

_exit_turn:
    ; print winnings and funds
    
    ; player wins
    mov ax, 0x00
    mov al, byte player_num_wins
    mov cx, 0x0a        ; base
    
_wp_num_to_char_loop:
    call _num_to_char
    cmp ax, 0x00
    jg _wp_num_to_char_loop
  
_wp_print:
    ; player_wins print
    mov ah, 0x13
    mov cx, 0x0d        ; length of string to be printed
    mov bx, 0
    mov es, bx
    mov bp, OFFSET player_wins
    mov dl, 0
    int 0x10
    
    mov si, OFFSET player_wins_to_print
    
_wp_print_loop:
    ; takes from stack and sets up for print
    cmp sp, 0x0000      ; check for empty stack
    jnl _wp_final_print
    pop ax
    mov word [si], ax
    inc si
    jmp _wp_print_loop
    
    
_wp_final_print:
    mov ah, 0x13
    mov cx, 0x0a        ; length of string to be printed
    mov bx, 0
    mov es, bx
    mov bp, OFFSET player_wins_to_print
    mov dl, 0
    int 0x10
    
    mov si, OFFSET player_wins_to_print
    add si, 0x09        ; end of win list
    
_wp_clear_wins:
    cmp si, OFFSET player_wins_to_print
    jnge _wp_exit_clear_wins
    mov byte [si], 0x00
    jmp _wp_clear_wins
    
_wp_exit_clear_wins:
    ; comp wins
    mov ax, 0x00
    mov al, byte comp_num_wins
    mov cx, 0x0a        ; base
    
_wc_num_to_char_loop:
    call _num_to_char
    cmp ax, 0x00
    jg _wc_num_to_char_loop
  
_wc_print:
    ; comp_wins print
    mov ah, 0x13
    mov cx, 0x0f        ; length of string to be printed
    mov bx, 0
    mov es, bx
    mov bp, OFFSET comp_wins
    mov dl, 0
    int 0x10
    
    mov si, OFFSET comp_wins_to_print
    
_wc_print_loop:
    ; takes from stack and sets up for print
    cmp sp, 0x0000      ; check for empty stack
    jnl _wc_final_print
    pop ax
    mov word [si], ax
    inc si
    jmp _wc_print_loop
    
    
_wc_final_print:
    mov ah, 0x13
    mov cx, 0x0a        ; length of string to be printed
    mov bx, 0
    mov es, bx
    mov bp, OFFSET comp_wins_to_print
    mov dl, 0
    int 0x10
    
    mov si, OFFSET comp_wins_to_print
    add si, 0x09        ; end of win list
    
_wc_clear_wins:
    cmp si, OFFSET comp_wins_to_print
    jnge _wc_exit_clear_wins
    mov byte [si], 0x00
    jmp _wc_clear_wins
    
_wc_exit_clear_wins:
    ; player funds
    mov ax, 0x00
    mov al, byte player_funds
    mov cx, 0x0a        ; base
    
_fp_num_to_char_loop:
    call _num_to_char
    cmp ax, 0x00
    jg _fp_num_to_char_loop
  
_fp_print:
    ; player_money print
    mov ah, 0x13
    mov cx, 0x0d        ; length of string to be printed
    mov bx, 0
    mov es, bx
    mov bp, OFFSET player_money
    mov dl, 0
    int 0x10
    
    mov si, OFFSET player_funds_to_print
    
_fp_print_loop:
    ; takes from stack and sets up for print
    cmp sp, 0x0000      ; check for empty stack
    jnl _fp_final_print
    pop ax
    mov word [si], ax
    inc si
    jmp _fp_print_loop
    
    
_fp_final_print:
    mov ah, 0x13
    mov cx, 0x0a        ; length of string to be printed
    mov bx, 0
    mov es, bx
    mov bp, OFFSET player_funds_to_print
    mov dl, 0
    int 0x10
    
    mov si, OFFSET player_funds_to_print
    add si, 0x09        ; end of funds list
    
_fp_clear_funds:
    cmp si, OFFSET player_funds_to_print
    jnge _fp_exit_clear_funds
    mov byte [si], 0x00
    jmp _fp_clear_funds
    
_fp_exit_clear_funds:
    ; computer funds
    mov ax, 0x00
    mov al, byte comp_funds
    mov cx, 0x0a        ; base
    
_fc_num_to_char_loop:
    call _num_to_char
    cmp ax, 0x00
    jg _fc_num_to_char_loop
  
_fc_print:
    ; comp_money print
    mov ah, 0x13
    mov cx, 0x0d        ; length of string to be printed
    mov bx, 0
    mov es, bx
    mov bp, OFFSET comp_money
    mov dl, 0
    int 0x10
    
    mov si, OFFSET comp_funds_to_print
    
_fc_print_loop:
    ; takes from stack and sets up for print
    cmp sp, 0x0000      ; check for empty stack
    jnl _fc_final_print
    pop ax
    mov word [si], ax
    inc si
    jmp _fc_print_loop
    
    
_fc_final_print:
    mov ah, 0x13
    mov cx, 0x0a        ; length of string to be printed
    mov bx, 0
    mov es, bx
    mov bp, OFFSET comp_funds_to_print
    mov dl, 0
    int 0x10
    
    mov si, OFFSET comp_funds_to_print
    add si, 0x09        ; end of funds list
    
_fc_clear_funds:
    cmp si, OFFSET comp_funds_to_print
    jnge _fc_exit_clear_funds
    mov byte [si], 0x00
    jmp _fc_clear_funds
    
_fc_exit_clear_funds:
    ; print continue prompt
    mov ah, 0x13
    mov cx, 0x14        ; length of string to be printed
    mov bx, 0
    mov es, bx
    mov bp, OFFSET continue_prompt
    mov dl, 0
    int 0x10
    
    ; store in continue_buffer
    mov ah, 0x0a
    lea dx, word continue_buffer
    int 0x21
    
    ; subtract 0x30 from val in continue_buffer
    mov si, OFFSET h_s_buffer
    add si, 0x02
    mov al, byte [si]
    sub al, 0x30
    
    ; * val in al
    ; * if 1, jmp to round_loop
    ; * if 0, end game
    
_check_all_cards_used:
    ; * checks decks to see if all cards have been used
    ; * if yes, compare player_card_val and comp_card_val to see who won
    ; * increment wins and handle funds accordingly
    ; * jump to either _final_player_win or _final_comp_win

_final_player_win:
    ; print player_win message
    mov ah, 0x13
    mov cx, 0x1c        ; length of string to be printed
    mov bx, 0
    mov es, bx
    mov bp, OFFSET final_player_win
    mov dl, 0
    int 0x10
    
    ; jump to _end_prog
    jmp _end_prog
    
_final_comp_win:
    ; print comp_win message
    mov ah, 0x13
    mov cx, 0x1e        ; length of string to be printed
    mov bx, 0
    mov es, bx
    mov bp, OFFSET final_comp_win
    mov dl, 0
    int 0x10
    
    ; jump to _end_prog
    jmp _end_prog

_end_game:
    ; * compare accumulated wins
    ; * jump to either _final_player_win or _final_comp_win
    
_end_prog:

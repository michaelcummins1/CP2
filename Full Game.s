; CS 274
; CP2
;
; @author: Michael Cummins and Isabelle Son
; @purpose: Creating a player vs computer blackjack game
cards:
    ; store byte rep of cards
    
decks:
    ; store parallel list that keeps track of used cards
    
bet_prompt: db "How much would you like bet?"
invalid_bet: db "Invalid bet!"
deck_prompt: db "How many decks would you like to use?"
difficulty_prompt: db "Difficulty: 1-Easy, 2-Normal, 3-Hard"
h_s_prompt: db "1-Hit, 0-Stay or 2-Forfeit?"
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

bet_buffer:
    db 0xff     ; maximum value to read
    db 0x00     ; actual value read after INT
    db [0x00, 0x04]     ; buffer of the right size
    
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
    
player_bet_to_print: db [0x00, 0x0a]
comp_bet_to_print: db [0x00, 0x0a]

player_cards_to_print: db [0x00, 0x15]  ; 21 spaces, can at most be A+2+3+4+5+6 before loss/win
comp_cards_to_print: db [0x00, 0x15]

def _check_bet {
    ; check if inital bet is $10-1000
    ; store 1 in a register if valid, 0 if not
}

def _comp_funds {
    ; based on difficulty, assign value to comp_funds
    ; easy - 50% of player funds
    ; normal - 100% of player funds
    ; hard - 150% of player funds
}

def _comp_bet {

    ; how to decide?
    
    ; conservative - under-bet by 20%
    ; normal - ret user bet
    ; aggressive - outmatch bet by 30%
    ret
}

def _char_to_num {
    ; converts all chars to number, moves backwards
    ; cx designated accumulator, si pointer
    ret
}

def _num_to_char {
    ; queues character rep of cards/bet/wins to be printed
    ; ax / cx -> remainder (dx) to char
    ; continue until 0
    ret
}

start:
    ; SETUP
    ; print prompt for number of decks
    ; store in deck_buffer
    ; subtract 0x30 from val in buffer,
    ; move to num_decks
    
_enter_amount:
    ; print prompt for player funds
    ; obtain user input for bet ($10-$1000) -> buffer
    ; move si to the last location of bet
    call _char_to_num
    ; bet value now stored in cx
    ; move to player_funds
    call _check_bet
    ; if 0 in designated register, jump to _enter_amount
    
    call _comp_funds
    ; move val to comp_funds
    
    ; computer risk level?
    
    ; print difficulty prompt
    ; store in difficulty_buffer
    ; subtract 0x30 from val in buffer,
    ; move to difficulty
    
    
_round_loop:
    ; actions performed every round
    ; check funds:
    ; if comp_funds insufficient, jump to _final_player_win
    ; if player_funds insufficient, jump to _final_comp_win
    
    ; print prompt bet and store in buffer
    ; move si to last location of bet
    call _char_to_num
    ; move from cx to player_bet
    ; check if funds > bet, 
    ; if not, print invalid bet, go back to _turn_loop
    
    call _comp_bet
    ; check if funds > bet,
    ; if not, move all funds to bet
    
    ; implement random card choosing
    ; 1 card to player, 1 card to computer
    ; add card values to player_card_val and computer_card_val
    ; handle card assignment
    ; print cards
    
_turn_loop:
    ; actual "get to 21"
_player_turn:
    ; ask player to hit, stay, or forfeit
    ; put input into h_s_buffer
    ; subtract 0x30, jump to _computer_turn if 0
    ; jump to _after_turn if 2
    ; generate random card
    ; add value to player_card_val
    ; add to player_cards_to_print
    ; print current cards
    ; if player_card_val > 21, jump to _comp_win
    ; if player_card_val = 21, jump to _player_win
    
_computer_turn:
    ; based on risk level, computer executes
    ; hit, stay, or forfeit
    ; if 0, jump to _check_both_stay
    ; jump to _after_turn if 2
    ; generate random card
    ; add value to comp_card_val
    ; add to comp_cards_to_print
    ; print current cards
    ; if comp_card_val > 21, jump to _player_win
    ; if comp_card_val = 21, jump to _comp_win
    ; jump to _turn_loop
    
__check_both_stay:
    ; if both player_h_s and comp_h_s are 0, jump to _cmp_vals
    ; jump to _turn_loop
    

_cmp_vals:
    ; if player_card_val > comp_card_val, jump to _player_win
    ; if comp_card_val > player_card_val, jump to _comp_win
    ; if equal, jump to _after_turn
    

_player_win:
    ; increase player_wins
    ; subtract comp_bet from comp_funds
    ; add comp_bet to player_funds
    ; jump to _after_turn
    
_comp_win:
    ; increase comp_wins
    ; subtract player_bet from player_funds
    ; add player_bet to comp_funds
    ; jump to _after_turn

_after_turn:
    ; print winnings and funds
    ; clear bet + bet_to_print
    ; clear cards
    ; print continue prompt
    ; subtract 0x30 from buffer
    ; if 1, jmp to round_loop
    ; if 0, end game
    
_check_all_cards_used:
    ; checks decks to see if all cards have been used
    ; if yes, compare player_card_val and comp_card_val to see who won
    ; increment wins and handle funds accordingly
    ; jump to either _final_player_win or _final_comp_win

_final_player_win:
    ; print player_win message
    ; jump to _end_prog
_final_comp_win:
    ; print comp_win message
    ; jump to _end_prog

_end_game:
    ; compare accumulated wins
    ; jump to either _final_player_win or _final_comp_win
    
_end_prog:
    

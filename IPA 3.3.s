; CS 274
; IPA 3.3
;
; @author: Michael Cummins
; @purpose: Creating trackers for betting, turn winning, and game winning

p_sum: db 0x14      ; Keeping track of the sum of the cards for the player and computer
c_sum: db 0x15      ; Will be varying in game given general sums for this IPA
                    ; (can change the numbers for various testing purposes)
p_bet: db 0x00      ; Player and computer betting slots
c_bet: db 0x00
c_bet_mode: db 0x02 ; Computer betting mode (0 = conservative, 1 = normal, 
                    ; 2 = aggressive)
p_total: dw 0x00c8  ; Total amount of money available for the player and computer
c_total: dw 0x00c8  ; (200 here just for testing purposes)
p_wins: db 0x00     ; Tracker for total wins for player and computer
c_wins: db 0x00

def _cons{
    ; 20% smaller computer bet
    mov al, byte p_bet
    mov bl, 0x04
    mul bl
    mov bl, 0x05
    div bl
    mov byte c_bet, al
    ret
    
}

def _norm{
    ; Equal computer bet
    mov al,  byte p_bet
    mov byte c_bet, al
    ret
}

def _aggr{
    ; 30% larger computer bet
    mov al, byte p_bet
    mov bl, 0x0d
    mul bl
    mov bl, 0x0a
    div bl
    mov byte c_bet, al
    ret
}

start:
    mov al, byte p_bet
    mov bl, byte c_bet
    add al, 0x32        ; Player bets 50 
    mov byte p_bet, al
    cmp byte c_bet_mode, 0x01
    jl _call_cons
    je _call_norm
    jg _call_aggr
_continue:
    mov al, byte p_sum
    mov bl, byte c_sum
    cmp al, 0x15
    je _p_win
    jg _c_win
    cmp bl, 0x15
    je _c_win
    jg _p_win
    cmp al, bl
    je _tie
    jg _p_win
    jl _c_win
    
_call_cons:
    call _cons
    jmp _continue
    
_call_norm:
    call _norm
    jmp _continue
    
_call_aggr:
    call _aggr
    jmp _continue
    
_tie:
    jmp _end
    ; Display to the user that the round ended in a tie so no one won
    ; (to be completed later with the rest of the front end work)

_p_win:
    mov al, byte p_wins
    inc al
    mov byte p_wins, al
    mov al, byte c_bet
    mov bl, byte p_total
    mov cl, byte c_total
    add bl, al
    sub cl, al
    cmp cl, 0x00
    jle _p_game_win                 ; If the computer has no money left, player wins
    mov byte p_total, bl
    mov byte c_total, cl
    jmp _end

_c_win:
    mov al, byte c_wins
    inc al
    mov byte c_wins, al
    mov al, byte p_bet
    mov bl, byte c_total
    mov cl, byte p_total
    add bl, al
    sub cl, al
    cmp cl, 0x00
    jle _c_game_win                 ; If teh player has no money left, computer wins
    mov byte c_total, bl
    mov byte p_total, cl
    jmp _end
    
_end:
    ; If ending due to no more cards or players choice then compare total wins
    ; If losing a bet results in no money then the player with money remaining 
    ; will count as the winner
    mov al, byte p_wins
    mov bl, byte c_wins
    cmp al, bl
    jg _p_game_win
    jl _c_game_win
    
_p_game_win:
    ; Display that the player won
    mov al, 0x11            ; Placeholder for testing

_c_game_win:
    ; Display that the computer won
    mov al, 0xcc            ; Placeholder for testing


    

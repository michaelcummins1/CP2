; CS 274
; IPA 3.5
;
; @author: Michael Cummins and Isabelle Son
; @purpose: Creating computer turn decision making

p_sum: db 0x15      ; Keeping track of the sum of the cards for the player and computer
c_sum: db 0x11      ; Will be varying in game given general sums for this IPA
                    ; (can change the numbers for various testing purposes)

start:
    ; Begins after player made their decision only if the decision was add a card
    ; or keep cards (if player folded their hand then computer auto wins)
    mov al, byte p_sum
    mov bl, byte c_sum
    sub al, bl
    cmp al, 10
    jge _fold
    mov bl, byte c_sum
    mov al, 0x15
    sub al, bl
    cmp al, 0x05
    jl _stand
    jmp _add
_stand:
    ; Keep cards the same and continue through the turn to turn evaluation
    mov ax, 0xffff      ; Testing purposes
_fold:
    ; Player automatically wins and recieves the bet of the computer
    mov ax, 0xeeee      ; Testing purposes
_add:
    ; Redo lehmer algorithm to compute another card for the computer
    mov ax, 0xdddd      ; Testing purposes
    
    

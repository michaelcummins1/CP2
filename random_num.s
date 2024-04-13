; init variables
x_0: dw 0x1563     ; current val, init as seed (x_0)
a: dw 0x05        ; multiplier (a)
m: dw 0x315d    ; large prime (m)
x_k: dw 0x00    ; current iteration
i: dw 4         ; stores number of iterations

def _lehmer_algo {
    ;compute
    mul bx      ; ax * bx
    div cx      ; ax mod cx, result in dx
    mov ax, dx
    mov word x_k, dx
    ret
}

start:
    mov ax, word x_0    ; load seed
    mov bx, word a      ; load regs bx, cx
    mov cx, word m
    mov si, 0           ; stores number of calls
    
_loop:
    cmp si, word i
    jge _choose_card
    call _lehmer_algo
    inc si
    jmp _loop

_choose_card:
    mov bx, 52
    div bx      ; ax mod bx, result in dx
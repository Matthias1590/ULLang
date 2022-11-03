%define ITOA_BUFFER_CAP 20

%macro putu 1
    fputu 1, %1
%endmacro

%macro fputu 2
    mov rax, %2
    call itoa
    mov rdx, rax
    fputs %1, rdx
%endmacro

segment .bss
    itoa_buffer: resb ITOA_BUFFER_CAP

segment .text
; Input in rax, output in rax
itoa:
    mov rbx, ITOA_BUFFER_CAP
    mov rcx, 10

    cmp rax, 0
    je itoa_zero

itoa_loop:
    xor rdx, rdx
    div rcx
    add dl, '0'
    mov byte [itoa_buffer + rbx - 2], dl

    dec rbx
    cmp rax, 0
    jne itoa_loop

    inc rbx
    jmp itoa_end

itoa_zero:
    mov byte [itoa_buffer + rbx - 2], "0"

itoa_end:
    lea rax, [itoa_buffer + rbx - 2]
    ret

; Input in rax, output in rax
atoi:
    mov rcx, rax
    mov rbx, 10
    mov rax, 0
    mov rdx, 0

atoi_loop:
    mov dl, byte [rcx]
    cmp dl, 0
    je atoi_stop

    sub dl, "0"
    push rdx
    mul rbx
    pop rdx
    add rax, rdx
    inc rcx
    jmp atoi_loop

atoi_stop:
    ret

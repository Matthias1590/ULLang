segment .text
strlen:
    mov rdi, 0

strlen_loop:
    cmp byte [rax + rdi], 0
    je strlen_end
    inc rdi
    jmp strlen_loop

strlen_end:
    mov rax, rdi
    ret

streq:
    mov rdx, 0

streq_loop:
    mov cl, byte [rbx + rdx]
    cmp byte [rax + rdx], cl
    jne streq_false
    inc rdx
    cmp cl, 0
    jne streq_loop

streq_true:
    mov rax, 1
    ret

streq_false:
    mov rax, 0
    ret

; Copies the string in rbx into rax and returns the amount of copied bytes in rax
strcpy:
    mov rcx, 0

strcpy_loop:
    mov dl, byte [rbx + rcx]
    mov byte [rax + rcx], dl

    inc rcx
    
    cmp dl, 0
    je strcpy_end

    jmp strcpy_loop

strcpy_end:
    mov rax, rcx
    ret

%macro puts 1
    fputs 1, %1
%endmacro

%macro fputs 2
    mov rax, %2
    call strlen
    mov rcx, rax
    write %1, %2, rcx
%endmacro
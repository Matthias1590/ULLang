%include "include/int.asm"
%include "include/str.asm"
%include "include/sys.asm"

%macro push_ret 1
    push rax
    mov rax, ret_stack
    add rax, qword [ret_stack_size]
    mov qword [rax], %1
    add qword [ret_stack_size], 8  ; sizeof(qword)
    pop rax
%endmacro

%macro pop_ret 1
    push rax
    sub qword [ret_stack_size], 8  ; sizeof(qword)
    mov rax, ret_stack
    add rax, qword [ret_stack_size]
    mov %1, qword [rax]
    pop rax
%endmacro

%macro enter 0
    ; Pop from stack into return stack
    pop r15
    push_ret r15
%endmacro

%macro return 0
    ; Pop from return stack into stack
    pop_ret r15
    push r15

    ret
%endmacro

segment .bss
    putc_buffer: resb 1
    ret_stack: resq 1024
    ret_stack_size: resq 1

segment .text
ul_print:
enter
    pop rdx
    putu rdx
    puts newline
return

ul_putu:
enter
    pop rdx
    putu rdx
return

ul_puts:
enter
    pop rdx
    puts rdx
return

ul_putc:
enter
    pop rax
    mov byte [putc_buffer], al
    write 1, putc_buffer, 1
return

ul_streq:
enter
    pop rbx
    pop rax
    call streq
    push rax
return

ul_strlen:
enter
    pop rax
    call strlen
    push rax
return

ul_swap:
enter
    pop rax
    pop rbx
    push rax
    push rbx
return

ul_$1:
enter
    pop rax
    pop rbx
    mov byte [rax], bl
return

ul_$8:
enter
    pop rax
    pop rbx
    mov qword [rax], rbx
return

ul_?8:
enter
    pop rax
    push qword [rax]
return

ul_strcpy:
enter
    pop rbx
    pop rax
    call strcpy
    push rax
return

ul_atoi:
enter
    pop rax
    call atoi
    push rax
return

ul_itoa:
enter
    pop rax
    call itoa
    push rax
return

ul_sys0:
enter
    pop rax
    syscall
    push rax
return

ul_sys1:
enter
    pop rax
    pop rdi
    syscall
    push rax
return

ul_sys2:
enter
    pop rax
    pop rsi
    pop rdi
    syscall
    push rax
return

ul_sys3:
enter
    pop rax
    pop rdx
    pop rsi
    pop rdi
    syscall
    push rax
return

ul_sys4:
enter
    pop rax
    pop r10
    pop rdx
    pop rsi
    pop rdi
    syscall
    push rax
return

ul_sys5:
enter
    pop rax
    pop r8
    pop r10
    pop rdx
    pop rsi
    pop rdi
    syscall
    push rax
return

ul_sys6:
enter
    pop rax
    pop r9
    pop r8
    pop r10
    pop rdx
    pop rsi
    pop rdi
    syscall
    push rax
return

segment .data
    newline: db 10, 0

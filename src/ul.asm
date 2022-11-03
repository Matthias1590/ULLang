; TODOS:
; - 

%include "include/sys.asm"
%include "include/str.asm"
%include "include/int.asm"

%define TOKEN_STACK_CAP 32768
%define INPUT_BUFFER_CAP 32768
%define STRING_BUFFER_CAP 32768
%define VARIABLE_STACK_CAP 16384  ; To define a variable at least 3 tokens must be used, thats why this is smaller than TOKEN_STACK_CAP
%define ARGV_CAP 64

; TODO: Implement by iterating over the name_list
%macro name_exists 1
    mov rax, 0
%endmacro

%macro try_open 3
    open %1, %2, %3
    cmp rax, 0
    jge %%_success
    
    fputs 1, failed_to_open
    fputs 1, quote
    fputs 1, %1
    fputs 1, quote
    fputs 1, newline
    exit 1
    
%%_success:
%endmacro

%macro func_puts 1
    fputs [func_desc], %1
%endmacro

%macro func_putu 1
    fputu [func_desc], %1
%endmacro

%macro func_enter 0
    func_puts asm_enter
    func_puts newline
%endmacro

%macro func_ret 0
    func_puts asm_return
    func_puts newline
%endmacro

%macro start_getter 1
    ; ul_?name:
    func_puts asm_ul
    func_puts question_mark
    func_puts r8
    func_puts colon
    func_puts newline
    func_enter
%endmacro

%macro start_setter 1
    ; ul_$name:
    func_puts asm_ul
    func_puts dollar_sign
    func_puts r8
    func_puts colon
    func_puts newline
    func_enter
%endmacro

struc Variable
    .name:     resq 1
    .bytesize: resq 1
endstruc

%macro push_var 2
    mov rax, variable_stack
    add rax, [variable_stack_size]
    mov qword [rax + Variable.name], %1
    mov qword [rax + Variable.bytesize], %2
    add qword [variable_stack_size], Variable_size
%endmacro

struc Token
    .type:     resq 1
    .value:    resq 1
    .jmp_data: resq 1
    .addr:     resq 1
endstruc

%define TOKEN_OP 0      ; Operators
%define TOKEN_WORD 1    ; Functions
%define TOKEN_NUMBER 2  ; Numbers
%define TOKEN_KEYW 3    ; Keywords
%define TOKEN_STRING 4  ; Strings

%define OP_PLUS 0
%define OP_MINUS 1
%define OP_GREATER 2
%define OP_DUP 3
%define OP_DROP 4
%define OP_READ1 5
%define OP_EQUAL 6
%define OP_MULT 7
%define OP_NOTEQ 8
%define OP_LESS 9
%define OP_COUNT 10

%define KEYW_IF 0
%define KEYW_END 1
%define KEYW_ELSE 2
%define KEYW_WHILE 3
%define KEYW_DO 4
%define KEYW_VAR 5
%define KEYW_FUNC 6
%define KEYW_RET 7
%define KEYW_COUNT 8

%define current_char byte [input_buffer + r8]

; Jump if no character
%macro jinc 1
    cmp r8, [input_size]
    jge %1
%endmacro

; Jump if space
%macro jis 2
    cmp %1, ' '
    je %2
    cmp %1, 10  ; \n
    je %2
    cmp %1, 13  ; \r
    je %2
%endmacro

; Jump if not digit
%macro jind 2
    cmp %1, '0'
    jl %2
    cmp %1, '9'
    jg %2
%endmacro

; Jump if streq
%macro jistreq 1
    call streq
    cmp rax, 1
    je %1
%endmacro

%macro push_token 2
    mov rcx, token_stack
    add rcx, [token_stack_size]
    mov qword [rcx + Token.type], %1
    mov qword [rcx + Token.value], %2
    push rax
    mov rax, qword [token_stack_size]
    mov qword [rcx + Token.addr], rax
    pop rax
    add qword [token_stack_size], Token_size
%endmacro

%macro assert_eq 2
    cmp %1, %2
    je %%_true

    puts assertion_failed
    puts space
    puts file
    puts colon
    putu __LINE__
    puts newline
    exit 1

%%_true:
%endmacro

%macro assert_g 2
    cmp %1, %2
    jg %%_true

    puts assertion_failed
    puts space
    puts file
    puts colon
    putu __LINE__
    puts newline
    exit 1

%%_true:
%endmacro

%macro assert_token_type 2
    assert_eq qword [%1 + Token.type], %2
%endmacro

%macro todo 0
    puts todo_at
    puts space
    puts file
    puts colon
    putu __LINE__
    puts newline
    exit 1
%endmacro

%macro unreachable 0
    puts unreachable_at
    puts space
    puts file
    puts colon
    putu __LINE__
    puts newline
    exit 1
%endmacro

%macro text_puts 1
    fputs [output_desc], %1
%endmacro

%macro text_putu 1
    fputu [output_desc], %1
%endmacro

%macro bss_puts 1
    fputs [bss_desc], %1
%endmacro

%macro bss_putu 1
    fputu [bss_desc], %1
%endmacro

%macro data_puts 1
    fputs [data_desc], %1
%endmacro

%macro data_putu 1
    fputu [data_desc], %1
%endmacro

segment .bss
    token_stack: resb Token_size * TOKEN_STACK_CAP
    token_stack_size: resq 1

    crossref_stack: resb Token_size * TOKEN_STACK_CAP
    crossref_stack_size: resq 1

    variable_stack: resb Variable_size * VARIABLE_STACK_CAP
    variable_stack_size: resq 1

    word_buffer: resb INPUT_BUFFER_CAP

    input_buffer: resb INPUT_BUFFER_CAP
    input_size: resq 1
    input_desc: resq 1

    output_desc: resq 1
    bss_desc: resq 1
    data_desc: resq 1
    func_desc: resq 1

    name_list: resb INPUT_BUFFER_CAP
    name_list_size: resq 1
    is_in_func: resb 1

    string_list: resb STRING_BUFFER_CAP
    string_list_size: resq 1

    argc: resq 1
    argv: resq ARGV_CAP

segment .text
global _start
_start:
    ; TODO: Use execve or some syscall to run nasm after generating the assembly
    
    ; Read argc
    pop qword [argc]

    ; Validate argc
    cmp qword [argc], 2
    mov rbx, 0  ; stderr
    mov rcx, 1  ; exit code 1
    jl print_usage

    ; Read argv
    mov rbx, 0
read_argv_loop:
    pop qword [argv + rbx]
    cmp qword [argv + rbx], 0
    je read_argv_end

    add rbx, 8  ; sizeof(qword)
    jmp read_argv_loop

read_argv_end:
    ; Open input file
    try_open qword [argv + 8], O_RDONLY, S_IRWXU
    mov [input_desc], rax

    ; Read input file
    read [input_desc], input_buffer, INPUT_BUFFER_CAP
    mov [input_size], rax

    ; Close input file
    close [input_desc]

    ; Tokenize
    call tokenize

    ; Print tokens
    ; call print_tokens
    ; puts newline

    ; Crossreference
    call crossref_tokens

    ; Compile
    call compile_tokens

    exit 0

; rbx = fd, rcx = exit code
print_usage:
    fputs rbx, invalid_usage
    fputs rbx, newline
    exit rcx

redefining_name:
    fputs 1, redefinition_of
    fputs 1, quote
    fputs 1, r8
    fputs 1, quote
    fputs 1, newline
    exit 1

print_failed_to_open:
    fputs 1, failed_to_open
    fputs 1, quote
    fputs 1, qword [argv + 8]
    fputs 1, quote
    fputs 1, newline
    exit 1

tokenize:
    ; Tokenize input
    mov r8, 0

tokenize_loop:
    jinc tokenize_end
    call skip_space
    jinc tokenize_end
    call read_token
    jmp tokenize_loop

tokenize_end:
    ret

; Crossreferences blocks
crossref_tokens:
    mov r13, 0

crossref_tokens_loop:
    cmp r13, [token_stack_size]
    je crossref_tokens_end

    lea r12, [token_stack + r13]

    cmp qword [r12 + Token.type], TOKEN_KEYW
    je crossref_keyw

    ; Make sure any non keywords are in a function
    assert_eq byte [is_in_func], 1
    jmp crossref_tokens_done

crossref_keyw:
    cmp qword [r12 + Token.value], KEYW_IF
    je crossref_if
    
    cmp qword [r12 + Token.value], KEYW_END
    je crossref_end

    cmp qword [r12 + Token.value], KEYW_ELSE
    je crossref_else

    cmp qword [r12 + Token.value], KEYW_WHILE
    je crossref_while

    cmp qword [r12 + Token.value], KEYW_DO
    je crossref_do

    cmp qword [r12 + Token.value], KEYW_VAR
    je crossref_var

    ; TODO: Read previous todo, same thing goes for functions
    cmp qword [r12 + Token.value], KEYW_FUNC
    je crossref_func

    ; Returns dont need to be crossreferenced
    cmp qword [r12 + Token.value], KEYW_RET
    je crossref_tokens_done

    unreachable

crossref_tokens_done:
    add r13, Token_size
    jmp crossref_tokens_loop

crossref_tokens_end:
    ; Make sure there are no more tokens left on the crossref_stack
    ; TODO: Report location of unclosed block (should be at the top of crossref_stack) once locations are added
    assert_eq qword [crossref_stack_size], 0
    ret

crossref_ret:
    todo
    jmp crossref_tokens_done

crossref_if:
    call push_crossref
    jmp crossref_tokens_done

crossref_end:
    ; Pop if/else and make it jump to end (if only jumps to end when false)
    ; rcx = pointer to matching if/else
    call pop_crossref
    mov rcx, qword [rcx]

    ; Make sure the popped token is if/else
    cmp qword [rcx + Token.value], KEYW_IF
    je crossref_end_close_if
    cmp qword [rcx + Token.value], KEYW_ELSE
    je crossref_end_close_else
    cmp qword [rcx + Token.value], KEYW_DO
    je crossref_end_close_do
    cmp qword [rcx + Token.value], KEYW_FUNC
    je crossref_end_close_func

    ; TODO: Turn this into an error message
    unreachable  ; We're trying to close a block thats not started with if/else

crossref_end_close_if:
crossref_end_close_else:
    push rax
    mov rax, qword [r12 + Token.addr]
    mov qword [rcx + Token.jmp_data], rax

    ; Set self.jmp_data to self.addr
    mov rax, qword [r12 + Token.addr]
    mov qword [r12 + Token.jmp_data], rax
    pop rax
    jmp crossref_tokens_done

crossref_end_close_do:
    ; Make end (r12) jump to do.jmp_data (while.addr)
    push rax
    mov rax, qword [rcx + Token.jmp_data]
    mov qword [r12 + Token.jmp_data], rax

    ; Make do (rcx) jump to after end (r12) if false
    mov rax, qword [r12 + Token.addr]
    mov qword [rcx + Token.jmp_data], rax
    pop rax

    jmp crossref_tokens_done

crossref_end_close_func:
    ; Change the end keyword to a return keyword so it works with compilation
    mov qword [r12 + Token.value], KEYW_RET

    mov byte [is_in_func], 0
    jmp crossref_tokens_done

crossref_else:
    ; Pop if and make it jump to after else (if only jumps to after else when false)
    call pop_crossref
    mov rcx, qword [rcx]

    ; Make sure the popped token is if
    cmp qword [rcx + Token.value], KEYW_IF
    je crossref_else_valid

    unreachable  ; We're trying to close a block with else thats not started with if

crossref_else_valid:
    push rax
    mov rax, qword [r12 + Token.addr]
    mov qword [rcx + Token.jmp_data], rax
    pop rax

    call push_crossref
    jmp crossref_tokens_done

crossref_while:
    call push_crossref
    jmp crossref_tokens_done

crossref_do:
    ; Pop while
    call pop_crossref
    mov rcx, qword [rcx]

    ; Store while.addr in do.jmp_data
    push rax
    mov rax, qword [rcx + Token.addr]
    mov qword [r12 + Token.jmp_data], rax
    pop rax

    ; Push do so end can close it
    call push_crossref
    jmp crossref_tokens_done

crossref_var:
    ; TODO: Maybe make crossreferencing of variables declare them so they can be referenced before their definition?

    ; Skip the next 2 tokens (TODO: Type check them so we dont skip other tokens and cause any errors that way)
    add r13, Token_size
    add r13, Token_size
    lea r12, [token_stack + r13]

    jmp crossref_tokens_done

crossref_func:
    assert_eq byte [is_in_func], 0  ; Trying to define a function inside of another function
    
    mov byte [is_in_func], 1
    call push_crossref
    jmp crossref_tokens_done

; r12 = *Token
push_crossref:
    mov rcx, crossref_stack
    add rcx, [crossref_stack_size]
    mov qword [rcx], r12
    add qword [crossref_stack_size], 8  ; sizeof(qword)
    ret

; Pops the top of the crossref stack into r14
pop_crossref:
    ; Check if the crossref stack is empty
    assert_g qword [crossref_stack_size], 0  ; The stack is empty, we're trying to close a non existant block

    ; Pop from the stack
    mov rcx, crossref_stack
    sub qword [crossref_stack_size], 8  ; sizeof(qword)
    add rcx, [crossref_stack_size]
    ret

; Compiles all tokens and writes the assembly to the output file
compile_tokens:
    ; Open bss file
    try_open bss_path, O_WRONLY | O_CREAT | O_TRUNC, S_WRITE
    mov [bss_desc], rax

    bss_puts asm_segment
    bss_puts space
    bss_puts dot
    bss_puts asm_bss
    bss_puts newline
    
    ; Open data file
    try_open data_path, O_WRONLY | O_CREAT | O_TRUNC, S_WRITE
    mov [data_desc], rax

    data_puts asm_segment
    data_puts space
    data_puts dot
    data_puts asm_data
    data_puts newline

    ; Open funcs file
    try_open func_path, O_WRONLY | O_CREAT | O_TRUNC, S_WRITE
    mov [func_desc], rax

    func_puts asm_segment
    func_puts space
    func_puts dot
    func_puts asm_text
    func_puts newline

    ; Open output file
    try_open output_path, O_WRONLY | O_CREAT | O_TRUNC, S_WRITE
    mov [output_desc], rax

    ; %include "include/std.asm"
    text_puts asm_include_std
    text_puts newline
    ; %include "out/bss.asm"
    text_puts asm_include_bss
    text_puts newline
    ; %include "out/data.asm"
    text_puts asm_include_data
    text_puts newline
    ; %include "out/func.asm"
    text_puts asm_include_func
    text_puts newline
    ; segment .text
    text_puts asm_segment        
    text_puts space        
    text_puts dot
    text_puts asm_text
    text_puts newline
    ; global _start
    text_puts asm_global
    text_puts space
    text_puts asm_entry
    text_puts newline

    mov r13, 0

compile_tokens_loop:
    cmp r13, [token_stack_size]
    je compile_tokens_end

    lea r12, [token_stack + r13]

    ; r12 = Token*
    cmp qword [r12 + Token.type], TOKEN_NUMBER
    je compile_number

    cmp qword [r12 + Token.type], TOKEN_OP
    je compile_op

    cmp qword [r12 + Token.type], TOKEN_KEYW
    je compile_keyw

    cmp qword [r12 + Token.type], TOKEN_WORD
    je compile_word

    cmp qword [r12 + Token.type], TOKEN_STRING
    je compile_string

    unreachable

compile_token_done:
    add r13, Token_size
    jmp compile_tokens_loop

compile_tokens_end:
    ; _start:
    text_puts asm_entry
    text_puts colon
    text_puts newline
    ; call ul_main
    text_puts asm_call
    text_puts space
    text_puts asm_ul
    text_puts main
    text_puts newline
    ; exit 0
    text_puts asm_exit
    text_puts space
    text_putu 0
    text_puts newline

    close [output_desc]
    ret

compile_number:
    ; push Token.value
    text_puts asm_push
    text_puts space
    text_putu qword [r12 + Token.value]
    text_puts newline
    jmp compile_token_done

compile_op:
    cmp qword [r12 + Token.value], OP_PLUS
    je compile_plus

    cmp qword [r12 + Token.value], OP_MINUS
    je compile_minus

    cmp qword [r12 + Token.value], OP_GREATER
    je compile_greater

    cmp qword [r12 + Token.value], OP_DUP
    je compile_dup

    cmp qword [r12 + Token.value], OP_DROP
    je compile_drop

    cmp qword [r12 + Token.value], OP_READ1
    je compile_read1

    cmp qword [r12 + Token.value], OP_EQUAL
    je compile_equal

    cmp qword [r12 + Token.value], OP_MULT
    je compile_mult

    cmp qword [r12 + Token.value], OP_NOTEQ
    je compile_noteq

    cmp qword [r12 + Token.value], OP_LESS
    je compile_less

    unreachable

    puts unimplemented_op
    puts quote
    putu qword [r12 + Token.value]
    puts quote
    puts newline
    exit 1

compile_op_done:
    jmp compile_token_done

compile_plus:
    ; pop rax
    text_puts asm_pop
    text_puts space
    text_puts asm_rax
    text_puts newline
    ; pop rbx
    text_puts asm_pop
    text_puts space
    text_puts asm_rbx
    text_puts newline
    ; add rbx,rax
    text_puts asm_add
    text_puts space
    text_puts asm_rbx
    text_puts comma
    text_puts asm_rax
    text_puts newline
    ; push rbx
    text_puts asm_push
    text_puts space
    text_puts asm_rbx
    text_puts newline
    jmp compile_op_done

compile_minus:
    ; pop rax
    text_puts asm_pop
    text_puts space
    text_puts asm_rax
    text_puts newline
    ; pop rbx
    text_puts asm_pop
    text_puts space
    text_puts asm_rbx
    text_puts newline
    ; sub rbx,rax
    text_puts asm_sub
    text_puts space
    text_puts asm_rbx
    text_puts comma
    text_puts asm_rax
    text_puts newline
    ; push rbx
    text_puts asm_push
    text_puts space
    text_puts asm_rbx
    text_puts newline
    jmp compile_op_done

compile_greater:
    ; pop rax
    text_puts asm_pop
    text_puts space
    text_puts asm_rax
    text_puts newline
    ; pop rbx
    text_puts asm_pop
    text_puts space
    text_puts asm_rbx
    text_puts newline
    ; mov rcx, 0
    text_puts asm_mov
    text_puts space
    text_puts asm_rcx
    text_puts comma
    text_putu 0
    text_puts newline
    ; mov rdx, 1
    text_puts asm_mov
    text_puts space
    text_puts asm_rdx
    text_puts comma
    text_putu 1
    text_puts newline
    ; cmp rbx,rax
    text_puts asm_cmp
    text_puts space
    text_puts asm_rbx
    text_puts comma
    text_puts asm_rax
    text_puts newline
    ; cmovg rcx, rdx
    text_puts asm_cmovg
    text_puts space
    text_puts asm_rcx
    text_puts comma
    text_puts asm_rdx
    text_puts newline
    ; push rcx
    text_puts asm_push
    text_puts space
    text_puts asm_rcx
    text_puts newline
    jmp compile_op_done

compile_dup:
    ; pop rax
    text_puts asm_pop
    text_puts space
    text_puts asm_rax
    text_puts newline
    ; push rax
    text_puts asm_push
    text_puts space
    text_puts asm_rax
    text_puts newline
    ; push rax
    text_puts asm_push
    text_puts space
    text_puts asm_rax
    text_puts newline
    jmp compile_op_done

compile_drop:
    ; pop rax
    text_puts asm_pop
    text_puts space
    text_puts asm_rax
    text_puts newline
    jmp compile_op_done

compile_equal:
    ; mov rax, 0
    text_puts asm_mov
    text_puts space
    text_puts asm_rax
    text_puts comma
    text_putu 0
    text_puts newline
    ; mov rdx, 1
    text_puts asm_mov
    text_puts space
    text_puts asm_rdx
    text_puts comma
    text_putu 1
    text_puts newline
    ; pop rbx
    text_puts asm_pop
    text_puts space
    text_puts asm_rbx
    text_puts newline
    ; pop rcx
    text_puts asm_pop
    text_puts space
    text_puts asm_rcx
    text_puts newline
    ; cmp rbx, rcx
    text_puts asm_cmp
    text_puts space
    text_puts asm_rbx
    text_puts comma
    text_puts asm_rcx
    text_puts newline
    ; cmove rax, rdx
    text_puts asm_cmove
    text_puts space
    text_puts asm_rax
    text_puts comma
    text_puts asm_rdx
    text_puts newline
    ; push rax
    text_puts asm_push
    text_puts space
    text_puts asm_rax
    text_puts newline
    jmp compile_op_done

compile_mult:
    ; pop rax
    text_puts asm_pop
    text_puts space
    text_puts asm_rax
    text_puts newline
    ; pop rbx
    text_puts asm_pop
    text_puts space
    text_puts asm_rbx
    text_puts newline
    ; mul rbx
    text_puts asm_mul
    text_puts space
    text_puts asm_rbx
    text_puts newline
    ; push rax
    text_puts asm_push
    text_puts space
    text_puts asm_rax
    text_puts newline
    jmp compile_op_done

compile_less:
; pop rax
    text_puts asm_pop
    text_puts space
    text_puts asm_rax
    text_puts newline
    ; pop rbx
    text_puts asm_pop
    text_puts space
    text_puts asm_rbx
    text_puts newline
    ; mov rcx, 0
    text_puts asm_mov
    text_puts space
    text_puts asm_rcx
    text_puts comma
    text_putu 0
    text_puts newline
    ; mov rdx, 1
    text_puts asm_mov
    text_puts space
    text_puts asm_rdx
    text_puts comma
    text_putu 1
    text_puts newline
    ; cmp rbx,rax
    text_puts asm_cmp
    text_puts space
    text_puts asm_rbx
    text_puts comma
    text_puts asm_rax
    text_puts newline
    ; cmovl rcx, rdx
    text_puts asm_cmovl
    text_puts space
    text_puts asm_rcx
    text_puts comma
    text_puts asm_rdx
    text_puts newline
    ; push rcx
    text_puts asm_push
    text_puts space
    text_puts asm_rcx
    text_puts newline
    jmp compile_op_done

compile_noteq:
    ; mov rax, 1
    text_puts asm_mov
    text_puts space
    text_puts asm_rax
    text_puts comma
    text_putu 1
    text_puts newline
    ; mov rdx, 0
    text_puts asm_mov
    text_puts space
    text_puts asm_rdx
    text_puts comma
    text_putu 0
    text_puts newline
    ; pop rbx
    text_puts asm_pop
    text_puts space
    text_puts asm_rbx
    text_puts newline
    ; pop rcx
    text_puts asm_pop
    text_puts space
    text_puts asm_rcx
    text_puts newline
    ; cmp rbx, rcx
    text_puts asm_cmp
    text_puts space
    text_puts asm_rbx
    text_puts comma
    text_puts asm_rcx
    text_puts newline
    ; cmove rax, rdx
    text_puts asm_cmove
    text_puts space
    text_puts asm_rax
    text_puts comma
    text_puts asm_rdx
    text_puts newline
    ; push rax
    text_puts asm_push
    text_puts space
    text_puts asm_rax
    text_puts newline
    jmp compile_op_done

compile_read1:
    ; pop rbx
    text_puts asm_pop
    text_puts space
    text_puts asm_rbx
    text_puts newline
    ; mov rax, 0
    text_puts asm_mov
    text_puts space
    text_puts asm_rax
    text_puts comma
    text_putu 0
    text_puts newline
    ; mov al, byte [rbx]
    text_puts asm_mov
    text_puts space
    text_puts asm_al
    text_puts comma
    text_puts asm_byte
    text_puts brack_left
    text_puts asm_rbx
    text_puts brack_right
    text_puts newline
    ; push rax
    text_puts asm_push
    text_puts space
    text_puts asm_rax
    text_puts newline
    jmp compile_op_done

compile_keyw:
    cmp qword [r12 + Token.value], KEYW_IF
    je compile_keyw_if

    cmp qword [r12 + Token.value], KEYW_END
    je compile_keyw_end

    cmp qword [r12 + Token.value], KEYW_ELSE
    je compile_keyw_else

    cmp qword [r12 + Token.value], KEYW_WHILE
    je compile_keyw_while

    cmp qword [r12 + Token.value], KEYW_DO
    je compile_keyw_do

    cmp qword [r12 + Token.value], KEYW_VAR
    je compile_keyw_var

    cmp qword [r12 + Token.value], KEYW_FUNC
    je compile_keyw_func

    cmp qword [r12 + Token.value], KEYW_RET
    je compile_keyw_ret

    unreachable

compile_keyw_done:
    jmp compile_token_done

compile_keyw_if:
    ; pop rax
    text_puts asm_pop
    text_puts space
    text_puts asm_rax
    text_puts newline
    ; cmp rax, 1
    text_puts asm_cmp
    text_puts space
    text_puts asm_rax
    text_puts comma
    text_putu 1
    text_puts newline
    ; jne addr_?
    text_puts asm_jne
    text_puts space
    text_puts asm_addr
    text_putu qword [r12 + Token.jmp_data]
    text_puts newline
    jmp compile_keyw_done

compile_keyw_end:
    ; jmp addr_?
    text_puts asm_jmp
    text_puts space
    text_puts asm_addr
    text_putu qword [r12 + Token.jmp_data]
    text_puts newline
    ; addr_?:
    text_puts asm_addr
    text_putu qword [r12 + Token.addr]
    text_puts colon
    text_puts newline
    jmp compile_keyw_done

compile_keyw_else:
    ; jmp addr_?
    text_puts asm_jmp
    text_puts space
    text_puts asm_addr
    text_putu qword [r12 + Token.jmp_data]
    text_puts newline
    ; addr_?:
    text_puts asm_addr
    text_putu qword [r12 + Token.addr]
    text_puts colon
    text_puts newline
    jmp compile_keyw_done

compile_keyw_while:
    ; addr_?:
    text_puts asm_addr
    text_putu qword [r12 + Token.addr]
    text_puts colon
    text_puts newline
    jmp compile_keyw_done

compile_keyw_do:
    ; Jump to end if top is false
    ; pop rax
    text_puts asm_pop
    text_puts space
    text_puts asm_rax
    text_puts newline
    ; cmp rax, 1
    text_puts asm_cmp
    text_puts space
    text_puts asm_rax
    text_puts comma
    text_putu 1
    text_puts newline
    ; jne addr_?
    text_puts asm_jne
    text_puts space
    text_puts asm_addr
    text_putu qword [r12 + Token.jmp_data]
    text_puts newline
    jmp compile_keyw_done

compile_keyw_var:
    ; Read name into r8
    add r13, Token_size
    lea r12, [token_stack + r13]
    assert_token_type r12, TOKEN_WORD
    mov r8, qword [r12 + Token.value]

    ; Read size into r9
    add r13, Token_size
    lea r12, [token_stack + r13]
    assert_token_type r12, TOKEN_NUMBER
    mov r9, qword [r12 + Token.value]

    push_var r8, r9

    ; Allocate variable
    ; ul_name: db size
    bss_puts asm_ul
    bss_puts r8
    bss_puts colon
    bss_puts asm_resb
    bss_puts space
    bss_putu r9
    bss_puts newline

    ; Define address
    ; ul_@name:
    func_puts asm_ul
    func_puts at_symbol
    func_puts r8
    func_puts colon
    func_puts newline
    func_enter

    ; push ul_name
    func_puts asm_push
    func_puts space
    func_puts asm_ul
    func_puts r8
    func_puts newline
    func_ret

    ; Define getter and setter
    cmp r9, 1
    je write_getset_byte

    cmp r9, 2
    je write_getset_word
    
    cmp r9, 4
    je write_getset_dword
    
    cmp r9, 8
    je write_getset_qword
    
compile_keyw_var_done:
    jmp compile_keyw_done

; TODO: Autogenerate @func_name function
compile_keyw_func:
    ; Read name into r8
    add r13, Token_size
    lea r12, [token_stack + r13]
    assert_token_type r12, TOKEN_WORD
    mov r8, qword [r12 + Token.value]

    name_exists r8
    cmp rax, 1
    je redefining_name

    mov rbx, r8
    call create_name

    ; ul_?:
    text_puts asm_ul
    text_puts r8
    text_puts colon
    text_puts newline
    ; enter
    text_puts asm_enter
    text_puts newline
    jmp compile_keyw_done

compile_keyw_ret:
    ; return
    text_puts asm_return
    text_puts newline
    jmp compile_keyw_done

; name in r8
write_getset_byte:
    start_getter r8

    ; mov rax, 0
    func_puts asm_mov
    func_puts space
    func_puts asm_rax
    func_puts comma
    func_putu 0
    func_puts newline
    ; mov al, byte [ul_name]
    func_puts asm_mov
    func_puts space
    func_puts asm_al
    func_puts comma
    func_puts asm_byte
    func_puts brack_left
    func_puts asm_ul
    func_puts r8
    func_puts brack_right
    func_puts newline
    ; push rax
    func_puts asm_push
    func_puts space
    func_puts asm_rax
    func_puts newline

    func_ret

    start_setter r8

    ; pop rax
    func_puts asm_pop
    func_puts space
    func_puts asm_rax
    func_puts newline
    ; mov byte [ul_name], al
    func_puts asm_mov
    func_puts space
    func_puts asm_byte
    func_puts brack_left
    func_puts asm_ul
    func_puts r8
    func_puts brack_right
    func_puts comma
    func_puts asm_al
    func_puts newline

    func_ret
    jmp compile_keyw_var_done

write_getset_word:
    start_getter r8

    ; mov rax, 0
    func_puts asm_mov
    func_puts space
    func_puts asm_rax
    func_puts comma
    func_putu 0
    func_puts newline
    ; mov ax, word [ul_name]
    func_puts asm_mov
    func_puts space
    func_puts asm_ax
    func_puts comma
    func_puts asm_word
    func_puts brack_left
    func_puts asm_ul
    func_puts r8
    func_puts brack_right
    func_puts newline
    ; push rax
    func_puts asm_push
    func_puts space
    func_puts asm_rax
    func_puts newline

    func_ret

    start_setter r8

    ; pop rax
    func_puts asm_pop
    func_puts space
    func_puts asm_rax
    func_puts newline
    ; mov word [ul_name], ax
    func_puts asm_mov
    func_puts space
    func_puts asm_word
    func_puts brack_left
    func_puts asm_ul
    func_puts r8
    func_puts brack_right
    func_puts comma
    func_puts asm_ax
    func_puts newline

    func_ret
    jmp compile_keyw_var_done

write_getset_dword:
    start_getter r8

    ; mov rax, 0
    func_puts asm_mov
    func_puts space
    func_puts asm_rax
    func_puts comma
    func_putu 0
    func_puts newline
    ; mov eax, dword [ul_name]
    func_puts asm_mov
    func_puts space
    func_puts asm_eax
    func_puts comma
    func_puts asm_dword
    func_puts brack_left
    func_puts asm_ul
    func_puts r8
    func_puts brack_right
    func_puts newline
    ; push rax
    func_puts asm_push
    func_puts space
    func_puts asm_rax
    func_puts newline

    func_ret

    start_setter r8

    ; pop rax
    func_puts asm_pop
    func_puts space
    func_puts asm_rax
    func_puts newline
    ; mov dword [ul_name], eax
    func_puts asm_mov
    func_puts space
    func_puts asm_dword
    func_puts brack_left
    func_puts asm_ul
    func_puts r8
    func_puts brack_right
    func_puts comma
    func_puts asm_eax
    func_puts newline

    func_ret
    jmp compile_keyw_var_done

write_getset_qword:
    start_getter r8

    ; mov rax, qword [ul_name]
    func_puts asm_mov
    func_puts space
    func_puts asm_rax
    func_puts comma
    func_puts asm_qword
    func_puts brack_left
    func_puts asm_ul
    func_puts r8
    func_puts brack_right
    func_puts newline
    ; push rax
    func_puts asm_push
    func_puts space
    func_puts asm_rax
    func_puts newline

    func_ret

    start_setter r8

    ; pop rax
    func_puts asm_pop
    func_puts space
    func_puts asm_rax
    func_puts newline
    ; mov qword [ul_name], rax
    func_puts asm_mov
    func_puts space
    func_puts asm_qword
    func_puts brack_left
    func_puts asm_ul
    func_puts r8
    func_puts brack_right
    func_puts comma
    func_puts asm_rax
    func_puts newline

    func_ret
    jmp compile_keyw_var_done

compile_word:
    ; call ul_?
    text_puts asm_call
    text_puts space
    text_puts asm_ul
    text_puts qword [r12 + Token.value]
    text_puts newline
    jmp compile_token_done

compile_string:
    ; string_?: db ?
    data_puts asm_string
    data_putu qword [r12 + Token.addr]  ; TODO: Turn this into the index into the string list
    data_puts colon
    data_puts asm_db
    data_puts space
    data_puts quote
    data_puts qword [r12 + Token.value]
    data_puts quote
    data_puts comma
    data_putu 0
    data_puts newline
    ; push string_?
    text_puts asm_push
    text_puts space
    text_puts asm_string
    text_putu qword [r12 + Token.addr]  ; TODO: Read previous todo
    text_puts newline
    jmp compile_token_done

; Prints all tokens to stdout
print_tokens:
    mov r13, 0

print_tokens_loop:
    cmp r13, [token_stack_size]
    je print_tokens_end

    lea r12, [token_stack + r13]

    ; Print token
    call token_puts

    add r13, Token_size
    jmp print_tokens_loop

print_tokens_end:
    ret

token_puts:
    call token_puts_addr
    puts space
    puts minus
    puts space
    puts type_is
    call token_puts_type
    puts comma
    puts space
    puts value_is
    call token_puts_value
    puts comma
    puts space
    call token_puts_value2
    puts newline
    ret

; Skips all space in the input
skip_space:
    jis current_char, skip_space_again
    jmp skip_space_end

skip_space_again:
    inc r8
    jinc skip_space_end
    jmp skip_space

skip_space_end:
    ret

; Reads a token and pushes it into the token stack
read_token:
    ; Branch based on the first character in the word buffer
    ; String
    mov al, byte [quote]
    cmp current_char, al
    je read_string

    ; If its not a string or digit, its an identifier
    jind current_char, read_identifier

    ; Its a digit so it must be a number
    call read_word
    mov rax, word_buffer
    call atoi
    push_token TOKEN_NUMBER, rax
    ret

read_string:
    ; Read string into the word buffer
    mov rax, 0
    mov byte [word_buffer], 0
    jmp read_string_skip

read_string_loop:
    mov bl, byte [quote]
    cmp current_char, bl
    je read_string_end

    mov bl, current_char
    mov byte [word_buffer + rax], bl

    inc rax
read_string_skip:
    jinc read_string_end
    inc r8  ; TODO: Figure out if r8 should be incremented before jinc read_string_end, cause i feel like it should
    jmp read_string_loop

read_string_end:
    mov byte [word_buffer + rax], 0
    inc r8

    call create_string
    push_token TOKEN_STRING, rax
    ret

create_string:
    mov rax, string_list
    add rax, [string_list_size]
    push rax  ; push start of name
    mov rbx, word_buffer
    call strcpy

    ; rax = bytes copied
    add [string_list_size], rax

    pop rax  ; pop start of name
    ret

read_identifier:
    call read_word
    mov rbx, word_buffer

    ; Comparing with operators and keywords
    %if KEYW_COUNT != 8
    todo
    %endif
    %if OP_COUNT != 10
    todo
    %endif

    mov rax, less
    jistreq read_less

    mov rax, noteq
    jistreq read_noteq

    mov rax, mult
    jistreq read_mult

    mov rax, equal
    jistreq read_equal

    mov rax, plus
    jistreq read_plus

    mov rax, minus
    jistreq read_minus

    mov rax, greater
    jistreq read_greater

    mov rax, _if
    jistreq read_if

    mov rax, end
    jistreq read_end

    mov rax, else
    jistreq read_else

    mov rax, while
    jistreq read_while

    mov rax, _do
    jistreq read_do
    
    mov rax, dup
    jistreq read_dup

    mov rax, drop
    jistreq read_drop

    mov rax, var
    jistreq read_var

    mov rax, read1
    jistreq read_read1

    mov rax, func
    jistreq read_func

    mov rax, _ret
    jistreq read_ret

    jmp read_name

    unreachable
    ret

    puts invalid_word
    puts quote
    puts rbx
    puts quote
    puts newline
    exit 1
    ret

read_less:
    push_token TOKEN_OP, OP_LESS
    ret

read_noteq:
    push_token TOKEN_OP, OP_NOTEQ
    ret

read_mult:
    push_token TOKEN_OP, OP_MULT
    ret

read_equal:
    push_token TOKEN_OP, OP_EQUAL
    ret

read_plus:
    push_token TOKEN_OP, OP_PLUS
    ret

read_minus:
    push_token TOKEN_OP, OP_MINUS
    ret

read_greater:
    push_token TOKEN_OP, OP_GREATER
    ret

read_if:
    push_token TOKEN_KEYW, KEYW_IF
    ret

read_end:
    push_token TOKEN_KEYW, KEYW_END
    ret

read_else:
    push_token TOKEN_KEYW, KEYW_ELSE
    ret

read_while:
    push_token TOKEN_KEYW, KEYW_WHILE
    ret

read_do:
    push_token TOKEN_KEYW, KEYW_DO
    ret

read_dup:
    push_token TOKEN_OP, OP_DUP
    ret

read_drop:
    push_token TOKEN_OP, OP_DROP
    ret

read_var:
    push_token TOKEN_KEYW, KEYW_VAR
    ret

read_read1:
    push_token TOKEN_OP, OP_READ1
    ret

read_func:
    push_token TOKEN_KEYW, KEYW_FUNC
    ret

read_ret:
    push_token TOKEN_KEYW, KEYW_RET
    ret

read_name:
    ; Copy the word buffer into the name list (stores address in rax)
    mov rbx, word_buffer
    call create_name

    push_token TOKEN_WORD, rax
    ret

; Copies the string in rbx into the name list and stores the address of the name in rax
create_name:
    mov rax, name_list
    add rax, [name_list_size]
    push rax  ; push start of name
    call strcpy

    ; rax = bytes copied
    add [name_list_size], rax

    pop rax  ; pop start of name
    ret

; Reads the input until the next space into the word buffer
read_word:
    mov rax, 0
    mov byte [word_buffer], 0

read_word_loop:
    jis current_char, read_word_end

    mov bl, current_char
    mov byte [word_buffer + rax], bl

    jinc read_word_end
    inc r8
    inc rax
    jmp read_word_loop

read_word_end:
    mov byte [word_buffer + rax], 0
    ret

token_puts_addr:
    putu qword [r12 + Token.addr]
    ret

; Token* in r12
token_puts_type:
    cmp qword [r12 + Token.type], TOKEN_NUMBER
    je token_puts_type_number

    cmp qword [r12 + Token.type], TOKEN_OP
    je token_puts_type_op

    cmp qword [r12 + Token.type], TOKEN_KEYW
    je token_puts_type_keyw

    cmp qword [r12 + Token.type], TOKEN_WORD
    je token_puts_type_word

    cmp qword [r12 + Token.type], TOKEN_STRING
    je token_puts_type_string

    unreachable
    ret

token_puts_type_number:
    puts number
    ret

token_puts_type_op:
    puts operator
    ret

token_puts_type_keyw:
    puts keyword
    ret

token_puts_type_word:
    puts _word
    ret

token_puts_type_string:
    puts string
    ret

token_puts_value:
    cmp qword [r12 + Token.type], TOKEN_NUMBER
    je token_puts_value_number

    cmp qword [r12 + Token.type], TOKEN_OP
    je token_puts_value_op

    cmp qword [r12 + Token.type], TOKEN_KEYW
    je token_puts_value_keyw

    cmp qword [r12 + Token.type], TOKEN_WORD
    je token_puts_value_word

    cmp qword [r12 + Token.type], TOKEN_STRING
    je token_puts_value_string

    unreachable
    ret

token_puts_value_number:
    putu qword [r12 + Token.value]
    ret

token_puts_value_op:
    cmp qword [r12 + Token.value], OP_PLUS
    je token_puts_value_op_plus

    cmp qword [r12 + Token.value], OP_MINUS
    je token_puts_value_op_minus

    cmp qword [r12 + Token.value], OP_GREATER
    je token_puts_value_op_greater

    cmp qword [r12 + Token.value], OP_READ1
    je token_puts_value_op_read1

    cmp qword [r12 + Token.value], OP_LESS
    je token_puts_value_op_less

    cmp qword [r12 + Token.value], OP_DUP
    je token_puts_value_op_dup

    cmp qword [r12 + Token.value], OP_DROP
    je token_puts_value_op_drop

    cmp qword [r12 + Token.value], OP_EQUAL
    je token_puts_value_op_equal

    unreachable
    ret

token_puts_value_op_plus:
    puts quote
    puts plus
    puts quote
    ret

token_puts_value_op_minus:
    puts quote
    puts minus
    puts quote
    ret

token_puts_value_op_greater:
    puts quote
    puts greater
    puts quote
    ret

token_puts_value_op_read1:
    puts quote
    puts read1
    puts quote
    ret

token_puts_value_op_less:
    puts quote
    puts less
    puts quote
    ret

token_puts_value_op_dup:
    puts quote
    puts dup
    puts quote
    ret

token_puts_value_op_drop:
    puts quote
    puts drop
    puts quote
    ret

token_puts_value_op_equal:
    puts quote
    puts equal
    puts quote
    ret

token_puts_value_keyw:
    cmp qword [r12 + Token.value], KEYW_IF
    je token_puts_value_keyw_if

    cmp qword [r12 + Token.value], KEYW_END
    je token_puts_value_keyw_end

    cmp qword [r12 + Token.value], KEYW_ELSE
    je token_puts_value_keyw_else

    cmp qword [r12 + Token.value], KEYW_WHILE
    je token_puts_value_keyw_while

    cmp qword [r12 + Token.value], KEYW_DO
    je token_puts_value_keyw_do

    cmp qword [r12 + Token.value], KEYW_FUNC
    je token_puts_value_keyw_func

    cmp qword [r12 + Token.value], KEYW_RET
    je token_puts_value_keyw_ret

    cmp qword [r12 + Token.value], KEYW_VAR
    je token_puts_value_keyw_var

    unreachable
    ret

token_puts_value_keyw_if:
    puts quote
    puts _if
    puts quote
    ret

token_puts_value_keyw_end:
    puts quote
    puts end
    puts quote
    ret

token_puts_value_keyw_else:
    puts quote
    puts else
    puts quote
    ret

token_puts_value_keyw_while:
    puts quote
    puts while
    puts quote
    ret

token_puts_value_keyw_do:
    puts quote
    puts _do
    puts quote
    ret

token_puts_value_keyw_func:
    puts quote
    puts func
    puts quote
    ret

token_puts_value_keyw_ret:
    puts quote
    puts _ret
    puts quote
    ret

token_puts_value_keyw_var:
    puts quote
    puts var
    puts quote
    ret

token_puts_value_word:
    puts quote
    puts qword [r12 + Token.value]
    puts quote
    ret

; TODO: Consider merging this with token_puts_value_word
token_puts_value_string:
    puts quote
    puts qword [r12 + Token.value]
    puts quote
    ret

token_puts_value2:
    putu qword [r12 + Token.jmp_data]
    ret

; Hardcoded strings
segment .data
    ; Debug messages
    file: db __FILE__, 0
    todo_at: db "Todo at", 0
    unreachable_at: db "Unreachable at", 0
    invalid_word: db "Invalid word ", 0
    redefinition_of: db "Redefinition of ", 0
    type_is: db "Type: ", 0
    value_is: db "Value: ", 0
    invalid_token: db "Invalid token ", 0
    invalid_usage: db "Invalid usage", 0
    failed_to_open: db "Failed to open ", 0
    unimplemented_op: db "Unimplemented operator ", 0
    assertion_failed: db "Assertion failed at", 0
    main: db "main", 0
    number: db "Number", 0
    operator: db "Operator", 0
    keyword: db "Keyword", 0
    _word: db "Word", 0
    string: db "String", 0

    ; Single characters
    quote: db '"', 0
    space: db " ", 0
    newline: db 10, 0
    comma: db ",", 0
    colon: db ":", 0
    dot: db ".", 0
    question_mark: db "?", 0
    dollar_sign: db "$", 0
    at_symbol: db "@", 0
    brack_left: db "[", 0
    brack_right: db "]", 0

    ; Operators
    equal: db "=", 0
    noteq: db "!=", 0
    less: db "<", 0
    mult: db "*", 0
    plus: db "+", 0
    minus: db "-", 0
    greater: db ">", 0
    dup: db "dup", 0
    drop: db "drop", 0
    read1: db "?1", 0

    ; Keywords
    _if: db "if", 0
    end: db "end", 0
    else: db "else", 0
    while: db "while", 0
    _do: db "do", 0
    var: db "var", 0
    func: db "func", 0
    _ret: db "ret", 0

    ; Assembly
    asm_include_std: db '%include "include/std.asm"', 0
    asm_include_bss: db '%include "out/bss.asm"', 0
    asm_include_data: db '%include "out/data.asm"', 0
    asm_include_func: db '%include "out/func.asm"', 0
    asm_segment: db "segment", 0
    asm_text: db "text", 0
    asm_bss: db "bss", 0
    asm_data: db "data", 0
    asm_global: db "global", 0
    asm_entry: db "_start", 0
    asm_ret: db "ret", 0
    asm_resb: db "resb", 0
    asm_db: db "db", 0
    asm_qword: db "qword", 0
    asm_dword: db "dword", 0
    asm_word: db "word", 0
    asm_byte: db "byte", 0
    asm_mul: db "mul", 0
    asm_push: db "push", 0
    asm_pop: db "pop", 0
    asm_rax: db "rax", 0
    asm_eax: db "eax", 0
    asm_ax: db "ax", 0
    asm_al: db "al", 0
    asm_rbx: db "rbx", 0
    asm_rcx: db "rcx", 0
    asm_rdx: db "rdx", 0
    asm_r15: db "r15", 0
    asm_mov: db "mov", 0
    asm_cmovg: db "cmovg", 0
    asm_cmovl: db "cmovl", 0
    asm_cmove: db "cmove", 0
    asm_add: db "add", 0
    asm_sub: db "sub", 0
    asm_call: db "call", 0
    asm_exit: db "exit", 0
    asm_cmp: db "cmp", 0
    asm_jg: db "jg", 0
    asm_jne: db "jne", 0
    asm_jmp: db "jmp", 0
    asm_enter: db "enter", 0
    asm_return: db "return", 0
    asm_addr: db "addr_", 0
    asm_ul: db "ul_", 0
    asm_string: db "string_", 0

    ; TODO: Merge and unhardcode these filepaths
    output_path: db "./out/out.asm", 0
    bss_path: db "./out/bss.asm", 0
    data_path: db "./out/data.asm", 0
    func_path: db "./out/func.asm", 0

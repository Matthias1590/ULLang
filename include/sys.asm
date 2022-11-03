; Read
%define SYS_READ 0

%macro read 3
    mov rax, SYS_READ
    mov rdi, %1
    mov rsi, %2
    mov rdx, %3
    syscall
%endmacro

; Write
%define SYS_WRITE 1

%macro write 3
    mov rax, SYS_WRITE
    mov rdi, %1
    mov rsi, %2
    mov rdx, %3
    syscall
%endmacro

; Open
%define SYS_OPEN 2
%define O_RDONLY 0
%define O_WRONLY 1
%define O_CREAT 256
%define O_TRUNC 512
%define S_WRITE 128
%define S_IRWXU 448

%macro open 3
    mov rax, SYS_OPEN
    mov rdi, %1
    mov rsi, %2
    mov rdx, %3
    syscall
%endmacro

; Close
%define SYS_CLOSE 3

%macro close 1
    mov rax, SYS_CLOSE
    mov rdi, %1
    syscall
%endmacro

; Execve
%define SYS_EXECVE 59

%macro execve 3
    mov rax, SYS_EXECVE
    mov rdi, %1
    mov rsi, %2
    mov rdx, %3
    syscall
%endmacro

; Exit
%define SYS_EXIT 60

%macro exit 1
    mov rax, SYS_EXIT
    mov rdi, %1
    syscall
%endmacro
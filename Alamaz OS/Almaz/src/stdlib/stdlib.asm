; stdlib.asm - стандартная библиотека для Almaz
section .text

; Функция для вычисления длины строки
; Вход: rdi = указатель на строку
; Выход: rax = длина
global string_length
string_length:
    xor rax, rax
.loop:
    cmp byte [rdi + rax], 0
    je .end
    inc rax
    jmp .loop
.end:
    ret

; Функция для конкатенации строк
; Вход: rdi = str1, rsi = str2
; Выход: rax = новая строка (нужно выделить память)
global string_concat
string_concat:
    push rbp
    mov rbp, rsp

    ; Вычислить длины
    call string_length  ; len1 в rax
    mov r8, rax
    mov rdi, rsi
    call string_length  ; len2 в rax
    mov r9, rax

    ; Выделить память для новой строки
    mov rdi, r8
    add rdi, r9
    inc rdi  ; +1 для null
    call malloc
    mov r10, rax  ; destination

    ; Копировать str1
    mov rsi, [rbp+16]  ; str1
    mov rdi, r10
    mov rcx, r8
    rep movsb

    ; Копировать str2
    mov rsi, [rbp+24]  ; str2
    mov rcx, r9
    rep movsb

    ; Null terminator
    mov byte [rdi], 0

    mov rax, r10
    leave
    ret

; Функция для вывода числа
; Вход: rdi = число
global print_number
print_number:
    ; Простая реализация для положительных чисел
    push rbp
    mov rbp, rsp
    sub rsp, 32

    mov rax, rdi
    mov rcx, 10
    mov rbx, 0  ; счетчик цифр

.convert_loop:
    xor rdx, rdx
    div rcx
    add dl, '0'
    mov r8, rbp
    sub r8, 8
    sub r8, rbx
    mov [r8], dl
    inc rbx
    test rax, rax
    jnz .convert_loop

    ; Вывод
    mov rsi, rbp
    sub rsi, 8
    sub rsi, rbx
    mov rdx, rbx
    mov rax, 1  ; sys_write
    mov rdi, 1  ; stdout
    syscall

    leave
    ret

; Вспомогательная функция malloc (уже есть в main, но для полноты)
; global malloc
malloc:
    mov rax, 9        ; sys_mmap
    xor rsi, rsi      ; addr = NULL
    mov rdx, 0x3      ; PROT_READ | PROT_WRITE
    mov r10, 0x22     ; MAP_ANONYMOUS | MAP_PRIVATE
    mov r8, -1        ; fd = -1
    xor r9, r9        ; offset = 0
    syscall
    ret

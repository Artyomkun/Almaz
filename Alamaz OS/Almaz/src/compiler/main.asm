; main.asm - точка входа компилятора
section .data
source_code:
    db "int x = 42", 10
    db "print x", 10, 0

output_file: db "output.asm", 0

msg_tokenized: db "Tokenized", 10
msg_tokenized_len equ $ - msg_tokenized

msg_parsed: db "Parsed", 10
msg_parsed_len equ $ - msg_parsed

msg_generated: db "Generated", 10
msg_generated_len equ $ - msg_generated

msg_written: db "Written", 10
msg_written_len equ $ - msg_written

msg_start: db "Start", 10
msg_start_len equ $ - msg_start

msg_tokenize: db "Tokenize start", 10
msg_tokenize_len equ $ - msg_tokenize

msg_token_saved: db "Token saved", 10
msg_token_saved_len equ $ - msg_token_saved

msg_malloc: db "Malloc called", 10
msg_malloc_len equ $ - msg_malloc

msg_get_token: db "Get token", 10
msg_get_token_len equ $ - msg_get_token

section .bss
tokens: resq 100      ; массив токенов (100 максимум)
ast_root: resq 1      ; корень AST
asm_buffer: resb 4096 ; буфер для ассемблерного кода
heap: resb 65536      ; 64KB heap
current_heap_ptr: resq 1

section .text
global _start
global malloc
global strlen
global strcpy
global strcmp

extern parse_program
extern generate_code
extern get_next_token
extern TOKEN_SIZE
extern TOKEN_EOF

_start:
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_start
    mov rdx, msg_start_len
    syscall

    ; Инициализировать heap
    mov qword [current_heap_ptr], heap

    ; 1. Лексический анализ
    mov rdi, source_code
    mov rsi, tokens
    call tokenize_source

    mov rax, 1
    mov rdi, 1
    mov rsi, msg_tokenized
    mov rdx, msg_tokenized_len
    syscall

    ; 2. Синтаксический анализ
    mov rdi, tokens
    call parse_program
    mov [ast_root], rax

    mov rax, 1
    mov rdi, 1
    mov rsi, msg_parsed
    mov rdx, msg_parsed_len
    syscall

    ; 3. Генерация кода
    mov rdi, [ast_root]
    mov rsi, asm_buffer
    call generate_code

    mov rax, 1
    mov rdi, 1
    mov rsi, msg_generated
    mov rdx, msg_generated_len
    syscall

    ; 4. Запись в файл
    mov rdi, output_file
    mov rsi, asm_buffer
    call write_file

    mov rax, 1
    mov rdi, 1
    mov rsi, msg_written
    mov rdx, msg_written_len
    syscall
    
    ; 5. Ассемблирование (вызываем nasm)
    call assemble_program
    
    ; 6. Выход
    mov rax, 60      ; sys_exit
    xor rdi, rdi     ; код 0
    syscall

; Вспомогательные функции
tokenize_source:
    push rbp
    mov rbp, rsp

    mov rax, 1
    mov rdi, 1
    mov rsi, msg_tokenize
    mov rdx, msg_tokenize_len
    syscall

    ; rdi = source, rsi = tokens array
    mov rbx, rsi     ; save tokens array
    xor rcx, rcx     ; token count
    xor rdx, rdx     ; position
    
.token_loop:
    mov rsi, rdx     ; position
    call get_next_token
    mov r10, rax     ; token
    mov rdx, rsi     ; new position
    
    cmp byte [r10], TOKEN_EOF  ; token.type is offset 0
    je .done

    ; Сохраняем токен в массив
    mov [rbx + rcx*8], r10

    inc rcx

    jmp .token_loop

.done:
    ; Добавляем EOF token
    mov rdi, TOKEN_SIZE
    call malloc
    mov byte [rax], TOKEN_EOF  ; token.type is offset 0
    mov [rbx + rcx*8], rax
    leave
    ret

write_file:
    ; rdi = filename, rsi = buffer
    ; Создаем файл
    mov rax, 2        ; sys_open
    mov rdx, 0o644    ; permissions
    mov rcx, 0o101    ; O_CREAT | O_WRONLY
    syscall
    
    mov r8, rax       ; file descriptor
    
    ; Записываем
    mov rdi, rsi
    call strlen
    mov rdx, rax      ; length
    
    mov rax, 1        ; sys_write
    mov rdi, r8       ; fd
    mov rsi, asm_buffer
    syscall
    
    ; Закрываем файл
    mov rax, 3        ; sys_close
    mov rdi, r8
    syscall
    ret

assemble_program:
    ; Вызываем nasm и ld через sys_execve
    ; Это сложнее, пока просто вернем
    ret

; Системные функции
malloc:
    ; rdi = size
    mov rax, [current_heap_ptr]
    add [current_heap_ptr], rdi
    ret

strlen:
    ; rdi = string
    xor rax, rax
.loop:
    cmp byte [rdi + rax], 0
    je .done
    inc rax
    jmp .loop
.done:
    ret

strcpy:
    ; rdi = dest, rsi = src
    xor rcx, rcx
.copy:
    mov al, [rsi + rcx]
    mov [rdi + rcx], al
    test al, al
    jz .done
    inc rcx
    jmp .copy
.done:
    ret

strcmp:
    ; rdi = s1, rsi = s2
    xor rcx, rcx
.compare:
    mov al, [rdi + rcx]
    mov bl, [rsi + rcx]
    cmp al, bl
    jne .not_equal
    test al, al
    jz .equal
    inc rcx
    jmp .compare
.equal:
    xor rax, rax
    ret
.not_equal:
    mov rax, 1
    ret

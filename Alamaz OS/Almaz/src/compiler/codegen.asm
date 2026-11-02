; codegen.asm

; AST node structure offsets
AST_TYPE   equ 0    ; тип узла
AST_VALUE  equ 8    ; значение (число или указатель)
AST_LEFT   equ 16   ; левый ребенок
AST_RIGHT  equ 24   ; правый ребенок

; Типы узлов AST
NODE_NUMBER   equ 1
NODE_IDENT    equ 2
NODE_ASSIGN   equ 3
NODE_BINARY   equ 4
NODE_PRINT    equ 5
NODE_STRING   equ 6
NODE_IF       equ 7
NODE_WHILE    equ 8
NODE_DO_WHILE equ 9
NODE_BOOL     equ 10
NODE_BLOCK    equ 11
NODE_FUNC_DEF equ 12
NODE_FUNC_CALL equ 13
NODE_RETURN   equ 14
NODE_TRY      equ 15
NODE_CATCH    equ 16
NODE_THROW    equ 17

section .data
; Системные вызовы Linux x86_64
SYS_WRITE  equ 1
SYS_EXIT   equ 60
STDOUT     equ 1

; Таблица переменных
struc var_entry
    .name:   resq 1    ; указатель на имя
    .offset: resd 1    ; смещение от RBP
endstruc

VAR_ENTRY_SIZE equ 12

section .bss
variables: resb 1024   ; таблица переменных (100 entries max)
var_count: resq 1      ; количество переменных
stack_size: resq 1     ; размер стека для локальных переменных

section .text
global generate_code

extern malloc
extern strlen
extern strcpy
extern strcmp

; rdi = AST root
; rsi = буфер для ассемблерного кода
generate_code:
    push rbp
    mov rbp, rsp
    
    mov [rbp-8], rdi   ; AST
    mov [rbp-16], rsi  ; output buffer
    
    ; Генерируем пролог
    mov rdi, rsi
    mov rsi, prologue
    call strcpy
    
    ; Добавляем код для переменных
    mov rax, [rbp-8]
    call generate_from_node
    
    ; Генерируем эпилог
    mov rdi, [rbp-16]
    call strlen
    add rdi, rax
    mov rsi, epilogue
    call strcpy
    
    leave
    ret

generate_from_node:
    ; rax = узел AST
    mov bl, [rax + AST_TYPE]

    cmp bl, NODE_ASSIGN
    je .gen_assign

    cmp bl, NODE_PRINT
    je .gen_print

    cmp bl, NODE_NUMBER
    je .gen_number

    cmp bl, NODE_IDENT
    je .gen_ident

    cmp bl, NODE_BINARY
    je .gen_binary

    cmp bl, NODE_STRING
    je .gen_string

    cmp bl, NODE_IF
    je .gen_if

    cmp bl, NODE_WHILE
    je .gen_while

    cmp bl, NODE_BLOCK
    je .gen_block

    cmp bl, NODE_DO_WHILE
    je .gen_do_while

    cmp bl, NODE_FUNC_DEF
    je .gen_func_def

    cmp bl, NODE_FUNC_CALL
    je .gen_func_call

    cmp bl, NODE_RETURN
    je .gen_return

    cmp bl, NODE_TRY
    je .gen_try

    cmp bl, NODE_THROW
    je .gen_throw

    ret

.gen_assign:
    ; Присваивание: let x = выражение
    push rax

    ; Генерируем выражение (результат в RAX)
    mov rax, [rax + AST_LEFT]
    call generate_from_node

    pop rbx  ; восстанавливаем узел assign
    mov rcx, [rbx + AST_VALUE]  ; имя переменной
    
    ; Ищем или создаем переменную
    call find_or_create_var
    mov r8d, [rax + var_entry.offset]  ; смещение
    
    ; Генерируем mov [rbp - offset], rax
    mov rdi, [rbp-16]
    call strlen
    add rdi, rax
    
    ; Формируем инструкцию
    mov byte [rdi], 0x48  ; mov [rbp - X], rax
    mov byte [rdi+1], 0x89
    mov byte [rdi+2], 0x45
    
    neg r8d
    mov [rdi+3], r8b
    
    add rdi, 4
    mov byte [rdi], 0x90  ; nop (заглушка)
    
    ret

.gen_print:
    ; Вывод значения
    ; Сначала вычисляем выражение
    mov rax, [rax + AST_LEFT]
    call generate_from_node

    ; Теперь результат в RAX, нужно вывести
    ; Сохраняем RAX
    mov rdi, [rbp-16]
    call strlen
    add rdi, rax

    ; push rax
    mov word [rdi], 0x5048  ; push rax
    add rdi, 2

    ; mov rdi, 1 (stdout)
    mov dword [rdi], 0x01BF48  ; mov rdi, 1
    add rdi, 3

    ; mov rsi, rsp (адрес значения)
    mov word [rdi], 0xE648  ; mov rsi, rsp
    mov byte [rdi+2], 0x89
    add rdi, 3

    ; mov rdx, 8 (размер)
    mov dword [rdi], 0x08C248  ; mov rdx, 8
    add rdi, 3

    ; mov rax, 1 (sys_write)
    mov dword [rdi], 0x01B848  ; mov rax, 1
    add rdi, 3

    ; syscall
    mov word [rdi], 0x050F  ; syscall
    add rdi, 2

    ; add rsp, 8 (восстанавливаем стек)
    mov dword [rdi], 0xC48348  ; add rsp, 8
    mov byte [rdi+3], 0x08
    add rdi, 4

    ret

.gen_number:
    ; Загружаем число в RAX
    mov rcx, [rax + AST_VALUE]
    
    mov rdi, [rbp-16]
    call strlen
    add rdi, rax
    
    ; mov rax, число
    mov byte [rdi], 0x48  ; mov rax, imm64
    mov byte [rdi+1], 0xB8
    
    mov [rdi+2], rcx
    
    add rdi, 10
    ret

.gen_ident:
    ; Загружаем переменную из стека в RAX
    mov rcx, [rax + AST_VALUE]  ; имя
    call find_var
    mov r8d, [rax + var_entry.offset]

    mov rdi, [rbp-16]
    call strlen
    add rdi, rax

    ; mov rax, [rbp - offset]
    mov byte [rdi], 0x48
    mov byte [rdi+1], 0x8B
    mov byte [rdi+2], 0x45

    neg r8d
    mov [rdi+3], r8b

    add rdi, 4
    ret

.gen_binary:
    ; Генерируем бинарную операцию
    push rbx
    mov rbx, rax  ; сохраняем узел

    ; Левый операнд
    mov rax, [rbx + AST_LEFT]
    call generate_from_node
    push rax  ; результат левого

    ; Правый операнд
    mov rax, [rbx + AST_RIGHT]
    call generate_from_node
    mov rcx, rax  ; правый в RCX

    pop rax  ; левый в RAX

    ; Оператор
    mov dl, [rbx + AST_VALUE]
    cmp dl, '+'
    je .add_op
    cmp dl, '-'
    je .sub_op
    cmp dl, '*'
    je .mul_op
    cmp dl, '/'
    je .div_op
    cmp dl, '<'
    je .less_op
    cmp dl, '>'
    je .greater_op
    cmp dl, '='
    je .equal_op
    cmp dl, '!'
    je .not_equal_op
    cmp dl, '&'
    je .and_op
    cmp dl, '|'
    je .or_op

    .add_op:
    add rax, rcx
    jmp .binary_done

    .sub_op:
    sub rax, rcx
    jmp .binary_done

    .mul_op:
    imul rax, rcx
    jmp .binary_done

    .div_op:
    ; Деление: RAX / RCX
    mov rdx, 0
    idiv rcx
    jmp .binary_done

    .less_op:
    cmp rax, rcx
    setl al
    movzx rax, al
    jmp .binary_done

    .greater_op:
    cmp rax, rcx
    setg al
    movzx rax, al
    jmp .binary_done

    .equal_op:
    cmp rax, rcx
    sete al
    movzx rax, al
    jmp .binary_done

    .not_equal_op:
    cmp rax, rcx
    setne al
    movzx rax, al
    jmp .binary_done

    .and_op:
    and rax, rcx
    jmp .binary_done

    .or_op:
    or rax, rcx
    jmp .binary_done

    .binary_done:
    pop rbx
    ret

.gen_string:
    ; Загружаем строку в RAX
    mov rcx, [rax + AST_VALUE]

    mov rdi, [rbp-16]
    call strlen
    add rdi, rax

    ; mov rax, string_ptr
    mov byte [rdi], 0x48
    mov byte [rdi+1], 0xB8
    mov [rdi+2], rcx

    add rdi, 10
    ret

.gen_if:
    ; Генерируем if: condition, then, else
    push rbx
    mov rbx, rax

    ; Генерируем condition
    mov rax, [rbx + AST_LEFT]
    call generate_from_node

    ; Добавляем test rax, rax
    mov rdi, [rbp-16]
    call strlen
    add rdi, rax

    mov rsi, test_rax
    call strcpy
    mov byte [rdi], 10  ; \n

    ; Генерируем then block
    mov rax, [rbx + AST_RIGHT]
    call generate_from_node

    ; jmp end_if
    mov rdi, [rbp-16]
    call strlen
    add rdi, rax

    mov rsi, jmp_end
    call strcpy
    mov byte [rdi], 10  ; \n

    ; else_label:
    mov rdi, [rbp-16]
    call strlen
    add rdi, rax

    mov rsi, else_label
    call strcpy
    mov byte [rdi], 10  ; \n

    ; Генерируем else block (если есть)
    mov rcx, [rbx + AST_VALUE]
    test rcx, rcx
    jz .no_else
    mov rax, rcx
    call generate_from_node

    .no_else:
    ; end_if:
    mov rdi, [rbp-16]
    call strlen
    add rdi, rax

    mov rsi, end_if_label
    call strcpy
    mov byte [rdi], 10  ; \n

    pop rbx
    ret

.gen_while:
    ; Генерируем while: condition, body
    push rbx
    mov rbx, rax

    ; loop_start:
    ; condition
    mov rax, [rbx + AST_LEFT]
    call generate_from_node

    ; test rax, rax
    ; jz loop_end

    ; body
    mov rax, [rbx + AST_RIGHT]
    call generate_from_node

    ; jmp loop_start
    ; loop_end:

    pop rbx
    ret

.gen_block:
    ; Генерируем block: statements
    mov rax, [rax + AST_LEFT]
    test rax, rax
    jz .block_done
    call generate_from_node
    .block_done:
    ret

.gen_do_while:
    ; Генерируем do-while: body, then condition
    push rbx
    mov rbx, rax

    ; body
    mov rax, [rbx + AST_LEFT]
    call generate_from_node

    ; condition
    mov rax, [rbx + AST_RIGHT]
    call generate_from_node

    ; test rax, rax
    ; jnz loop_start

    pop rbx
    ret

.gen_func_def:
    ; func name() { body }
    push rbx
    mov rbx, rax

    ; Генерируем метку: func_name:
    mov rdi, [rbp-16]
    call strlen
    add rdi, rax

    mov rsi, [rbx + AST_VALUE]  ; имя функции
    call strcpy
    mov byte [rdi], ':'
    inc rdi
    mov byte [rdi], 10  ; \n
    inc rdi
    mov byte [rdi], 0

    ; Генерируем тело
    mov rax, [rbx + AST_LEFT]
    call generate_from_node

    ; ret
    mov rdi, [rbp-16]
    call strlen
    add rdi, rax
    mov dword [rdi], 0xC3C3C3C3  ; ret (повтор)
    add rdi, 1
    mov byte [rdi], 10  ; \n

    pop rbx
    ret

.gen_func_call:
    ; call func_name
    mov rcx, [rax + AST_VALUE]  ; имя

    mov rdi, [rbp-16]
    call strlen
    add rdi, rax

    ; call
    mov dword [rdi], 0x6C6C6163  ; "call"
    add rdi, 4
    mov byte [rdi], ' '
    inc rdi

    ; имя
    mov rsi, rcx
    call strcpy

    mov byte [rdi], 10  ; \n

    ret

.gen_return:
    ; return expr
    ; Вычисляем выражение
    mov rax, [rax + AST_LEFT]
    call generate_from_node

    ; ret
    mov rdi, [rbp-16]
    call strlen
    add rdi, rax
    mov byte [rdi], 0xC3  ; ret
    inc rdi
    mov byte [rdi], 10  ; \n

    ret

.gen_try:
    ; try { try_block } catch { catch_block }
    push rbx
    mov rbx, rax

    ; Генерируем try block
    mov rax, [rbx + AST_LEFT]
    call generate_from_node

    ; Генерируем catch block
    mov rax, [rbx + AST_RIGHT]
    call generate_from_node

    pop rbx
    ret

.gen_throw:
    ; throw expression
    ; Вычисляем выражение
    mov rax, [rax + AST_LEFT]
    call generate_from_node

    ; Для простоты, просто выводим ошибку и выходим
    mov rdi, [rbp-16]
    call strlen
    add rdi, rax

    ; mov rax, 60 ; exit
    mov dword [rdi], 0x3C48C3C3  ; mov rax, 60; ret (placeholder)
    add rdi, 4

    ret

find_or_create_var:
    ; Ищем переменную по имени rcx
    ; Если не найдена - создаем новую
    mov rsi, variables
    mov rdx, [var_count]
    
.search_loop:
    test rdx, rdx
    jz .create_new
    
    mov rdi, [rsi + var_entry.name]
    call strcmp
    cmp rax, 0
    je .found
    
    add rsi, VAR_ENTRY_SIZE
    dec rdx
    jmp .search_loop

.found:
    mov rax, rsi
    ret

.create_new:
    ; Вычисляем смещение для новой переменной
    mov eax, [stack_size]
    add eax, 8  ; каждая переменная занимает 8 байт
    mov [stack_size], eax
    
    ; Создаем запись
    mov rsi, variables
    mov rdx, [var_count]
    imul rdx, VAR_ENTRY_SIZE
    add rsi, rdx
    
    mov [rsi + var_entry.name], rcx
    mov [rsi + var_entry.offset], eax
    
    inc qword [var_count]
    mov rax, rsi
    ret

find_var:
    ; Только поиск, без создания
    mov rsi, variables
    mov rdx, [var_count]
    
.search:
    test rdx, rdx
    jz .not_found
    
    mov rdi, [rsi + var_entry.name]
    call strcmp
    cmp rax, 0
    je .found_var
    
    add rsi, VAR_ENTRY_SIZE
    dec rdx
    jmp .search

.found_var:
    mov rax, rsi
    ret

.not_found:
    ; Ошибка: переменная не найдена
    mov rax, 0
    ret

section .data
prologue:
    db "global _start", 10
    db "_start:", 10
    db "  push rbp", 10
    db "  mov rbp, rsp", 10
    db "  sub rsp, 64", 10, 0  ; 64 байта для локальных переменных

epilogue:
    db "  mov rsp, rbp", 10
    db "  pop rbp", 10
    db "  mov rax, 60", 10     ; sys_exit
    db "  mov rdi, 0", 10      ; exit code
    db "  syscall", 10, 0

test_rax: db "  test rax, rax", 0
jmp_end: db "  jmp end_if", 0
else_label: db "else_label:", 0
end_if_label: db "end_if:", 0

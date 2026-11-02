; parser.asm
section .data

; Типы токенов

msg_parse: db "Parse start", 10
msg_parse_len equ $ - msg_parse
TOKEN_EOF      equ 0
TOKEN_LET      equ 1
TOKEN_IDENT    equ 2
TOKEN_EQUAL    equ 3
TOKEN_NUMBER   equ 4
TOKEN_PLUS     equ 5
TOKEN_MINUS    equ 6
TOKEN_PRINT    equ 7
TOKEN_MULTIPLY equ 8
TOKEN_DIVIDE   equ 9
TOKEN_EQUAL_EQUAL equ 10
TOKEN_NOT_EQUAL equ 11
TOKEN_LESS     equ 12
TOKEN_GREATER  equ 13
TOKEN_AND      equ 14
TOKEN_OR       equ 15
TOKEN_STRING   equ 16
TOKEN_IF       equ 17
TOKEN_ELSE     equ 18
TOKEN_WHILE    equ 19
TOKEN_DO       equ 20
TOKEN_INT      equ 21
TOKEN_STRING_TYPE equ 22
TOKEN_BOOL     equ 23
TOKEN_LPAREN   equ 24
TOKEN_RPAREN   equ 25
TOKEN_LBRACE   equ 26
TOKEN_RBRACE   equ 27
TOKEN_FUNC     equ 28
TOKEN_RETURN   equ 29
TOKEN_INT8     equ 30
TOKEN_UINT8    equ 31
TOKEN_INT16    equ 32
TOKEN_UINT16   equ 33
TOKEN_INT32    equ 34
TOKEN_UINT32   equ 35
TOKEN_INT64    equ 36
TOKEN_UINT64   equ 37
TOKEN_INT128   equ 38
TOKEN_UINT128  equ 39
TOKEN_FLOAT16  equ 41
TOKEN_FLOAT32  equ 42
TOKEN_FLOAT64  equ 43
TOKEN_TRY      equ 44
TOKEN_CATCH    equ 45
TOKEN_EXCEPT   equ 46
TOKEN_THROW    equ 47
TOKEN_AS       equ 48
TOKEN_ELIF     equ 49

struc ast_node
    .type:       resb 1    ; тип узла
    .value:      resq 1    ; значение (число или указатель)
    .left:       resq 1    ; левый ребенок
    .right:      resq 1    ; правый ребенок
endstruc

NODE_SIZE equ 25  ; 1 + 8 + 8 + 8

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

section .text
global parse_program
global parse_let
global parse_print
global parse_var_decl
global parse_func
global parse_return
global parse_try
global parse_throw
global parse_do_while
global parse_expression

extern malloc
extern strcmp

; rdi = массив токенов
; Возвращает AST в rax
parse_program:
    push rbp
    mov rbp, rsp

    ; Лог
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_parse
    mov rdx, msg_parse_len
    syscall

    ; Создаем корень программы (пока пустой)
    mov rdi, NODE_SIZE
    call malloc
    mov [rbp-8], rax  ; root node
    
    ; Текущий токен
    mov qword [rbp-16], 0  ; token index
    
.parse_loop:
    ; Получаем текущий токен
    mov rcx, [rbp-16]
    shl rcx, 3         ; *8 (размер указателя)
    add rcx, rdi       ; rcx = &tokens[index]
    mov rcx, [rcx]     ; rcx = token
    
    ; Проверяем тип
    mov al, [rcx]  ; 0 is offset 0
    cmp al, TOKEN_EOF
    je parse_done
    
    cmp al, TOKEN_INT8
    je parse_var_decl

    cmp al, TOKEN_UINT8
    je parse_var_decl

    cmp al, TOKEN_INT16
    je parse_var_decl

    cmp al, TOKEN_UINT16
    je parse_var_decl

    cmp al, TOKEN_INT32
    je parse_var_decl

    cmp al, TOKEN_UINT32
    je parse_var_decl

    cmp al, TOKEN_INT64
    je parse_var_decl

    cmp al, TOKEN_UINT64
    je parse_var_decl

    cmp al, TOKEN_INT128
    je parse_var_decl

    cmp al, TOKEN_UINT128
    je parse_var_decl

    cmp al, TOKEN_BOOL
    je parse_var_decl

    cmp al, TOKEN_FLOAT16
    je parse_var_decl

    cmp al, TOKEN_FLOAT32
    je parse_var_decl

    cmp al, TOKEN_FLOAT64
    je parse_var_decl

    cmp al, TOKEN_INT
    je parse_var_decl

    cmp al, TOKEN_STRING_TYPE
    je parse_var_decl

    cmp al, TOKEN_LET
    je parse_let

    cmp al, TOKEN_PRINT
    je parse_print

    cmp al, TOKEN_IF
    je parse_if

    cmp al, TOKEN_WHILE
    je parse_while

    cmp al, TOKEN_DO
    je parse_do_while

    cmp al, TOKEN_FUNC
    je parse_func

    cmp al, TOKEN_RETURN
    je parse_return

    cmp al, TOKEN_TRY
    je parse_try

    cmp al, TOKEN_THROW
    je parse_throw

    ; Ошибка: ожидалось statement
    jmp parse_error

.handle_while:
    call parse_while
    call add_to_program
    ret

.handle_do_while:
    call parse_do_while
    call add_to_program
    ret

parse_let:
    ; Парсим: let идентификатор = выражение
    inc qword [rbp-16]  ; пропускаем 'let'
    
    ; Должен быть идентификатор
    call get_current_token
    cmp byte [rax], TOKEN_IDENT  ; 0 is offset 0
    jne parse_error
    
    ; Сохраняем имя переменной
    mov rbx, [rax + 8]  ; 8 is offset 8
    inc qword [rbp-16]  ; пропускаем идентификатор
    
    ; Должен быть '='
    call get_current_token
    cmp byte [rax + 0], TOKEN_EQUAL
    jne parse_error
    
    inc qword [rbp-16]  ; пропускаем '='
    
    ; Парсим выражение
    call parse_expression
    mov rcx, rax  ; expression node
    
    ; Создаем узел присваивания
    mov rdi, NODE_SIZE
    call malloc
    mov byte [rax + ast_node.type], NODE_ASSIGN
    mov [rax + ast_node.value], rbx  ; имя переменной
    mov [rax + ast_node.left], rcx   ; выражение
    
    ; Добавляем к программе
    call add_to_program
    ret

parse_print:
    inc qword [rbp-16]  ; пропускаем 'print'
    call parse_expression
    mov rcx, rax
    
    ; Создаем узел print
    mov rdi, NODE_SIZE
    call malloc
    mov byte [rax + ast_node.type], NODE_PRINT
    mov [rax + ast_node.left], rcx
    
    call add_to_program
    ret

parse_var_decl:
    ; Парсим: тип идентификатор = выражение
    mov r8b, al  ; тип
    inc qword [rbp-16]  ; пропускаем тип

    ; Должен быть идентификатор
    call get_current_token
    cmp byte [rax + 0], TOKEN_IDENT
    jne parse_error

    ; Сохраняем имя переменной
    mov rbx, [rax + 8]  ; имя переменной
    inc qword [rbp-16]  ; пропускаем идентификатор

    ; Должен быть '='
    call get_current_token
    cmp byte [rax + 0], TOKEN_EQUAL
    jne parse_error

    inc qword [rbp-16]  ; пропускаем '='

    ; Парсим выражение
    call parse_expression
    mov rcx, rax  ; expression node

    ; Создаем узел присваивания
    mov rdi, NODE_SIZE
    call malloc
    mov byte [rax + ast_node.type], NODE_ASSIGN
    mov [rax + ast_node.value], rbx  ; имя переменной
    mov [rax + ast_node.left], rcx   ; выражение
    mov [rax + ast_node.right], r8   ; тип

    ; Добавляем к программе
    call add_to_program
    ret

parse_func:
    ; Парсим: func name() { statements }
    inc qword [rbp-16]  ; пропускаем 'func'

    ; Имя функции
    call get_current_token
    cmp byte [rax + 0], TOKEN_IDENT
    jne parse_error
    mov rbx, [rax + 8]  ; имя функции
    inc qword [rbp-16]

    ; Ожидаем (
    call get_current_token
    cmp byte [rax + 0], TOKEN_LPAREN
    jne parse_error
    inc qword [rbp-16]

    ; Ожидаем )
    call get_current_token
    cmp byte [rax + 0], TOKEN_RPAREN
    jne parse_error
    inc qword [rbp-16]

    ; Парсим тело
    call parse_block
    mov rcx, rax  ; тело

    ; Создаем узел func_def
    mov rdi, NODE_SIZE
    call malloc
    mov byte [rax + ast_node.type], NODE_FUNC_DEF
    mov [rax + ast_node.value], rbx  ; имя
    mov [rax + ast_node.left], rcx   ; тело

    call add_to_program
    ret

parse_return:
    inc qword [rbp-16]  ; пропускаем 'return'
    call parse_expression
    mov rcx, rax

    ; Создаем узел return
    mov rdi, NODE_SIZE
    call malloc
    mov byte [rax + ast_node.type], NODE_RETURN
    mov [rax + ast_node.left], rcx

    call add_to_program
    ret

.parse_if:
    call parse_if
    call add_to_program
    ret

parse_try:
    ; Парсим: try { statements } catch { statements }
    inc qword [rbp-16]  ; пропускаем 'try'

    ; Парсим try block
    call parse_block
    mov rbx, rax  ; try block

    ; Ожидаем catch или except
    call get_current_token
    cmp byte [rax + 0], TOKEN_CATCH
    je .catch_ok
    cmp byte [rax + 0], TOKEN_EXCEPT
    je .catch_ok
    jmp parse_error
.catch_ok:
    inc qword [rbp-16]

    ; Опционально (тип исключения)
    call get_current_token
    cmp byte [rax + 0], TOKEN_LPAREN
    jne .no_exception_type
    inc qword [rbp-16]  ; пропускаем (

    ; Тип исключения
    call get_current_token
    cmp byte [rax + 0], TOKEN_INT8
    jl parse_error
    cmp byte [rax + 0], TOKEN_FLOAT64
    jg parse_error
    inc qword [rbp-16]  ; пропускаем тип

    ; Опционально 'as identifier'
    call get_current_token
    cmp byte [rax + 0], TOKEN_AS
    jne .no_as
    inc qword [rbp-16]  ; пропускаем 'as'

    ; Идентификатор
    call get_current_token
    cmp byte [rax + 0], TOKEN_IDENT
    jne parse_error
    inc qword [rbp-16]  ; пропускаем идентификатор

.no_as:
    ; )
    call get_current_token
    cmp byte [rax + 0], TOKEN_RPAREN
    jne parse_error
    inc qword [rbp-16]
.no_exception_type:

    ; Парсим catch block
    call parse_block
    mov rcx, rax  ; catch block

    ; Создаем узел try
    mov rdi, NODE_SIZE
    call malloc
    mov byte [rax + ast_node.type], NODE_TRY
    mov [rax + ast_node.left], rbx   ; try
    mov [rax + ast_node.right], rcx  ; catch

    call add_to_program
    ret

parse_throw:
    inc qword [rbp-16]  ; пропускаем 'throw'
    call parse_expression
    mov rcx, rax

    ; Создаем узел throw
    mov rdi, NODE_SIZE
    call malloc
    mov byte [rax + ast_node.type], NODE_THROW
    mov [rax + ast_node.left], rcx

    call add_to_program
    ret

parse_expression:
    ; Парсер выражений: logic_expr
    push rbp
    mov rbp, rsp

    call parse_logic_expr

    leave
    ret

parse_logic_expr:
    ; Парсер логических выражений: comparison ((&& | ||) comparison)*
    push rbp
    mov rbp, rsp

    call parse_comparison

    .logic_loop:
    call get_current_token
    mov bl, [rax + 0]

    cmp bl, TOKEN_AND
    je .parse_and
    cmp bl, TOKEN_OR
    je .parse_or

    leave
    ret

    .parse_and:
    inc qword [rbp-16]
    push rax
    call parse_comparison
    mov rcx, rax
    pop rbx

    mov rdi, NODE_SIZE
    call malloc
    mov byte [rax + ast_node.type], NODE_BINARY
    mov byte [rax + ast_node.value], '&'
    mov [rax + ast_node.left], rbx
    mov [rax + ast_node.right], rcx

    jmp .logic_loop

    .parse_or:
    inc qword [rbp-16]
    push rax
    call parse_comparison
    mov rcx, rax
    pop rbx

    mov rdi, NODE_SIZE
    call malloc
    mov byte [rax + ast_node.type], NODE_BINARY
    mov byte [rax + ast_node.value], '|'
    mov [rax + ast_node.left], rbx
    mov [rax + ast_node.right], rcx

    jmp .logic_loop

parse_comparison:
    ; Парсер сравнений: term ((< | > | <= | >= | == | !=) term)*
    push rbp
    mov rbp, rsp

    call parse_term

    .comp_loop:
    call get_current_token
    mov bl, [rax + 0]

    cmp bl, TOKEN_LESS
    je .parse_less
    cmp bl, TOKEN_GREATER
    je .parse_greater
    cmp bl, TOKEN_EQUAL_EQUAL
    je .parse_eq
    cmp bl, TOKEN_NOT_EQUAL
    je .parse_ne

    leave
    ret

    .parse_less:
    inc qword [rbp-16]
    push rax
    call parse_term
    mov rcx, rax
    pop rbx

    mov rdi, NODE_SIZE
    call malloc
    mov byte [rax + ast_node.type], NODE_BINARY
    mov byte [rax + ast_node.value], '<'
    mov [rax + ast_node.left], rbx
    mov [rax + ast_node.right], rcx

    jmp .comp_loop

    .parse_greater:
    inc qword [rbp-16]
    push rax
    call parse_term
    mov rcx, rax
    pop rbx

    mov rdi, NODE_SIZE
    call malloc
    mov byte [rax + ast_node.type], NODE_BINARY
    mov byte [rax + ast_node.value], '>'
    mov [rax + ast_node.left], rbx
    mov [rax + ast_node.right], rcx

    jmp .comp_loop

    .parse_eq:
    inc qword [rbp-16]
    push rax
    call parse_term
    mov rcx, rax
    pop rbx

    mov rdi, NODE_SIZE
    call malloc
    mov byte [rax + ast_node.type], NODE_BINARY
    mov byte [rax + ast_node.value], '='
    mov [rax + ast_node.left], rbx
    mov [rax + ast_node.right], rcx

    jmp .comp_loop

    .parse_ne:
    inc qword [rbp-16]
    push rax
    call parse_term
    mov rcx, rax
    pop rbx

    mov rdi, NODE_SIZE
    call malloc
    mov byte [rax + ast_node.type], NODE_BINARY
    mov byte [rax + ast_node.value], '!'
    mov [rax + ast_node.left], rbx
    mov [rax + ast_node.right], rcx

    jmp .comp_loop

parse_if:
    ; Парсим: if (condition) { statements } [elif (condition) { statements }]* [else { statements }]
    push rbp
    mov rbp, rsp

    inc qword [rbp-16]  ; пропускаем 'if'

    ; Ожидаем (
    call get_current_token
    cmp byte [rax + 0], TOKEN_LPAREN
    jne parse_error
    inc qword [rbp-16]

    ; Парсим condition
    call parse_expression
    mov rbx, rax  ; condition

    ; Ожидаем )
    call get_current_token
    cmp byte [rax + 0], TOKEN_RPAREN
    jne parse_error
    inc qword [rbp-16]

    ; Парсим then block
    call parse_block
    mov rcx, rax  ; then block

    ; Проверяем elif или else
    call get_current_token
    cmp byte [rax + 0], TOKEN_ELIF
    je .parse_elif
    cmp byte [rax + 0], TOKEN_ELSE
    je .parse_else
    jmp .no_else

.parse_elif:
    ; elif - это else if, рекурсивно парсим
    inc qword [rbp-16]
    call parse_if  ; рекурсивно парсим оставшуюся часть
    mov rdx, rax   ; else block (который является другим if)
    jmp .create_if

.parse_else:
    inc qword [rbp-16]
    call parse_block
    mov rdx, rax  ; else block
    jmp .create_if

    .no_else:
    xor rdx, rdx  ; no else

    .create_if:
    ; Создаем узел if
    mov rdi, NODE_SIZE
    call malloc
    mov byte [rax + ast_node.type], NODE_IF
    mov [rax + ast_node.left], rbx    ; condition
    mov [rax + ast_node.right], rcx   ; then
    mov [rax + ast_node.value], rdx   ; else

    ; Для if не вызываем add_to_program, так как это может быть часть большего выражения
    ; Возвращаем узел
    leave
    ret

parse_while:
    ; Парсим: while (condition) { statements }
    push rbp
    mov rbp, rsp

    inc qword [rbp-16]  ; пропускаем 'while'

    ; Ожидаем (
    call get_current_token
    cmp byte [rax + 0], TOKEN_LPAREN
    jne parse_error
    inc qword [rbp-16]

    ; Парсим condition
    call parse_expression
    mov rbx, rax  ; condition

    ; Ожидаем )
    call get_current_token
    cmp byte [rax + 0], TOKEN_RPAREN
    jne parse_error
    inc qword [rbp-16]

    ; Парсим body
    call parse_block
    mov rcx, rax  ; body

    ; Создаем узел while
    mov rdi, NODE_SIZE
    call malloc
    mov byte [rax + ast_node.type], NODE_WHILE
    mov [rax + ast_node.left], rbx  ; condition
    mov [rax + ast_node.right], rcx ; body

    call add_to_program
    ret

parse_do_while:
    ; Парсим: do { statements } while (condition)
    push rbp
    mov rbp, rsp

    inc qword [rbp-16]  ; пропускаем 'do'

    ; Парсим body
    call parse_block
    mov rbx, rax  ; body

    ; Ожидаем while
    call get_current_token
    cmp byte [rax + 0], TOKEN_WHILE
    jne parse_error
    inc qword [rbp-16]

    ; Ожидаем (
    call get_current_token
    cmp byte [rax + 0], TOKEN_LPAREN
    jne parse_error
    inc qword [rbp-16]

    ; Парсим condition
    call parse_expression
    mov rcx, rax  ; condition

    ; Ожидаем )
    call get_current_token
    cmp byte [rax + 0], TOKEN_RPAREN
    jne parse_error
    inc qword [rbp-16]

    ; Создаем узел do_while
    mov rdi, NODE_SIZE
    call malloc
    mov byte [rax + ast_node.type], NODE_DO_WHILE
    mov [rax + ast_node.left], rbx  ; body
    mov [rax + ast_node.right], rcx ; condition

    call add_to_program
    ret

parse_block:
    ; Парсер блока: { statements }
    push rbp
    mov rbp, rsp

    ; Ожидаем {
    call get_current_token
    cmp byte [rax + 0], TOKEN_LBRACE
    jne parse_error
    inc qword [rbp-16]

    ; Создаем узел блока
    mov rdi, NODE_SIZE
    call malloc
    mov [rbp-8], rax  ; block node
    mov byte [rax + ast_node.type], NODE_BLOCK
    ; value будет указателем на список statements, но пока 0

    ; Парсим statements пока не }
    .block_loop:
    call get_current_token
    cmp byte [rax + 0], TOKEN_RBRACE
    je .block_end

    ; Парсим statement
    call parse_statement
    ; Добавляем к блоку (простая реализация: только один statement)
    mov rcx, [rbp-8]
    mov [rcx + ast_node.left], rax

    jmp .block_loop

    .block_end:
    inc qword [rbp-16]
    mov rax, [rbp-8]
    leave
    ret

parse_statement:
    ; Парсер statement: let | print | if | while | block
    push rbp
    mov rbp, rsp

    call get_current_token
    mov al, [rax + 0]

    cmp al, TOKEN_INT8
    je parse_var_decl_stmt

    cmp al, TOKEN_UINT8
    je parse_var_decl_stmt

    cmp al, TOKEN_INT16
    je parse_var_decl_stmt

    cmp al, TOKEN_UINT16
    je parse_var_decl_stmt

    cmp al, TOKEN_INT32
    je parse_var_decl_stmt

    cmp al, TOKEN_UINT32
    je parse_var_decl_stmt

    cmp al, TOKEN_INT64
    je parse_var_decl_stmt

    cmp al, TOKEN_UINT64
    je parse_var_decl_stmt

    cmp al, TOKEN_INT128
    je parse_var_decl_stmt

    cmp al, TOKEN_UINT128
    je parse_var_decl_stmt

    cmp al, TOKEN_BOOL
    je parse_var_decl_stmt

    cmp al, TOKEN_FLOAT16
    je parse_var_decl_stmt

    cmp al, TOKEN_FLOAT32
    je parse_var_decl_stmt

    cmp al, TOKEN_FLOAT64
    je parse_var_decl_stmt

    cmp al, TOKEN_INT
    je parse_var_decl_stmt

    cmp al, TOKEN_STRING_TYPE
    je parse_var_decl_stmt

    cmp al, TOKEN_LET
    je parse_let_stmt

    cmp al, TOKEN_PRINT
    je parse_print_stmt

    cmp al, TOKEN_IF
    je parse_if_stmt

    cmp al, TOKEN_WHILE
    je parse_while_stmt

    cmp al, TOKEN_DO
    je parse_do_while_stmt

    cmp al, TOKEN_FUNC
    je parse_func_stmt

    cmp al, TOKEN_RETURN
    je parse_return_stmt

    cmp al, TOKEN_TRY
    je parse_try_stmt

    cmp al, TOKEN_THROW
    je parse_throw_stmt

    cmp al, TOKEN_CATCH
    je parse_try_stmt  ; catch без try не имеет смысла, но для совместимости

    cmp al, TOKEN_EXCEPT
    je parse_try_stmt

    cmp al, TOKEN_LBRACE
    je parse_block_stmt

    jmp parse_error

    parse_let_stmt:
    call parse_let
    leave
    ret

    parse_print_stmt:
    call parse_print
    leave
    ret

    parse_if_stmt:
    call parse_if
    leave
    ret

    parse_while_stmt:
    call parse_while
    leave
    ret

    parse_do_while_stmt:
    call parse_do_while
    leave
    ret

    parse_var_decl_stmt:
    call parse_var_decl
    leave
    ret

    parse_func_stmt:
    call parse_func
    leave
    ret

    parse_return_stmt:
    call parse_return
    leave
    ret

    parse_try_stmt:
    call parse_try
    leave
    ret

    parse_throw_stmt:
    call parse_throw
    leave
    ret

    parse_block_stmt:
    call parse_block
    leave
    ret

parse_term:
    ; Парсер терма: factor ((*|/) factor)*
    push rbp
    mov rbp, rsp
    
    call parse_factor
    
    .term_loop:
    call get_current_token
    mov bl, [rax + 0]
    
    cmp bl, TOKEN_MULTIPLY
    je .parse_mul
    cmp bl, TOKEN_DIVIDE
    je .parse_div
    
    leave
    ret
    
    .parse_mul:
    inc qword [rbp-16]
    push rax
    call parse_factor
    mov rcx, rax
    pop rbx
    
    mov rdi, NODE_SIZE
    call malloc
    mov byte [rax + ast_node.type], NODE_BINARY
    mov byte [rax + ast_node.value], '*'
    mov [rax + ast_node.left], rbx
    mov [rax + ast_node.right], rcx
    
    jmp .term_loop
    
    .parse_div:
    inc qword [rbp-16]
    push rax
    call parse_factor
    mov rcx, rax
    pop rbx
    
    mov rdi, NODE_SIZE
    call malloc
    mov byte [rax + ast_node.type], NODE_BINARY
    mov byte [rax + ast_node.value], '/'
    mov [rax + ast_node.left], rbx
    mov [rax + ast_node.right], rcx
    
    jmp .term_loop

parse_factor:
    ; Парсер фактора: число, идентификатор или строка
    push rbp
    mov rbp, rsp
    
    call get_current_token
    mov bl, [rax + 0]
    
    cmp bl, TOKEN_NUMBER
    je .parse_number_expr
    
    cmp bl, TOKEN_IDENT
    je .parse_ident_expr
    
    cmp bl, TOKEN_STRING
    je .parse_string_expr
    
    ; Ошибка
    jmp parse_error

.parse_number_expr:
    mov rcx, [rax + 8]
    
    mov rdi, NODE_SIZE
    call malloc
    mov byte [rax + ast_node.type], NODE_NUMBER
    mov [rax + ast_node.value], rcx
    
    inc qword [rbp-16]
    leave
    ret

.parse_ident_expr:
    mov rcx, [rax + 8]

    ; Проверяем на вызов функции: ident (
    push rax
    inc qword [rbp-16]
    call get_current_token
    cmp byte [rax + 0], TOKEN_LPAREN
    je .parse_func_call
    pop rax

    ; Просто идентификатор
    mov rdi, NODE_SIZE
    call malloc
    mov byte [rax + ast_node.type], NODE_IDENT
    mov [rax + ast_node.value], rcx

    leave
    ret

.parse_func_call:
    ; Это вызов функции
    pop rbx  ; имя функции
    inc qword [rbp-16]  ; пропускаем (

    ; Парсим аргументы (пока пустые)
    call get_current_token
    cmp byte [rax + 0], TOKEN_RPAREN
    jne parse_error
    inc qword [rbp-16]  ; пропускаем )

    ; Создаем узел func_call
    mov rdi, NODE_SIZE
    call malloc
    mov byte [rax + ast_node.type], NODE_FUNC_CALL
    mov rcx, [rbx + 8]
    mov [rax + ast_node.value], rcx  ; имя функции

    leave
    ret

.parse_string_expr:
    mov rcx, [rax + 8]
    
    mov rdi, NODE_SIZE
    call malloc
    mov byte [rax + ast_node.type], NODE_STRING
    mov [rax + ast_node.value], rcx
    
    inc qword [rbp-16]
    leave
    ret

get_current_token:
    mov rcx, [rbp-16]
    shl rcx, 3
    add rcx, [rbp+16]  ; tokens array
    mov rax, [rcx]
    ret

add_to_program:
    ; Добавляем узел к программе (простейшая реализация)
    ret

parse_error:
    ; Выводим ошибку и выходим
    mov rax, 60  ; exit
    mov rdi, 1   ; код ошибки
    syscall

parse_done:
    mov rax, [rbp-8]  ; root node
    leave
    ret

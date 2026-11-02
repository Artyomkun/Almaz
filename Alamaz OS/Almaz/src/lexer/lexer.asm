; lexer.asm
section .data
; Типы токенов

msg_get_token: db "Get token", 10
msg_get_token_len equ $ - msg_get_token
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

; Структура токена
struc token
    .type:      resb 1    ; тип (1 байт)
    .value:     resq 1    ; значение (8 байт для чисел/указателей)
    .line:      resd 1    ; строка (4 байта)
    .column:    resd 1    ; колонка (4 байта)
endstruc

TOKEN_SIZE equ 17  ; размер структуры в байтах

; lexer.asm
section .text
global get_next_token
global TOKEN_SIZE
global TOKEN_EOF

extern malloc
extern strcmp

; rdi = указатель на исходный код
; rsi = текущая позиция
; Возвращает в rax указатель на токен, в rsi новую позицию
get_next_token:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; Лог
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_get_token
    mov rdx, msg_get_token_len
    syscall
    
    ; Сохраняем входные параметры
    mov [rbp-8], rdi   ; source
    mov [rbp-16], rsi  ; position
    
    ; Выделяем память под токен
    mov rdi, TOKEN_SIZE
    call malloc
    mov [rbp-24], rax  ; token ptr
    
    ; Получаем текущий символ
    mov rcx, [rbp-16]
    mov rdx, [rbp-8]
    add rdx, rcx
    movzx eax, byte [rdx]
    
    ; Пропускаем пробелы
.skip_spaces:
    cmp al, ' '
    je .next_char
    cmp al, 9          ; таб
    je .next_char
    cmp al, 10         ; новая строка
    je .next_char
    jmp .check_char
    
.next_char:
    inc rcx
    mov rdx, [rbp-8]
    add rdx, rcx
    movzx eax, byte [rdx]
    jmp .skip_spaces

.check_char:
    ; Конец файла?
    cmp al, 0
    je .eof
    
    ; Число?
    cmp al, '0'
    jl .not_number
    cmp al, '9'
    jg .not_number
    jmp .parse_number
    
.not_number:
    ; Буква? (идентификатор или ключевое слово)
    cmp al, 'a'
    jl .not_alpha
    cmp al, 'z'
    jle .parse_identifier
    cmp al, 'A'
    jl .not_alpha
    cmp al, 'Z'
    jle .parse_identifier
    
.not_alpha:
    ; Оператор?
    cmp al, '='
    je .check_equal
    cmp al, '+'
    je .parse_plus
    cmp al, '-'
    je .parse_minus
    cmp al, '*'
    je .parse_multiply
    cmp al, '/'
    je .parse_divide
    cmp al, '<'
    je .parse_less
    cmp al, '>'
    je .parse_greater
    cmp al, '&'
    je .check_and
    cmp al, '|'
    je .check_or
    cmp al, '!'
    je .check_not
    cmp al, '"'
    je .parse_string
    cmp al, '('
    je .parse_lparen
    cmp al, ')'
    je .parse_rparen
    cmp al, '{'
    je .parse_lbrace
    cmp al, '}'
    je .parse_rbrace

    ; Неизвестный символ
    jmp .error

.parse_number:
    ; Парсим целое число
    mov rdx, [rbp-8]   ; source
    add rdx, rcx       ; current position
    call parse_integer_at
    mov r8, rax        ; value
    mov r9, rdx        ; new position
    
    ; Заполняем токен
    mov rax, [rbp-24]  ; token
    mov byte [rax + token.type], TOKEN_NUMBER
    mov [rax + token.value], r8
    mov [rbp-16], r9   ; обновляем позицию
    
    jmp .done

.parse_identifier:
    ; Парсим идентификатор
    mov rdx, [rbp-8]
    add rdx, rcx
    call parse_identifier_at
    mov r8, rax        ; identifier string
    mov r9, rdx        ; new position
    
    ; Проверяем ключевые слова
    call is_keyword
    cmp rax, 0
    je .is_ident
    
    ; Это ключевое слово
    mov rbx, [rbp-24]
    mov byte [rbx + token.type], al  ; keyword type
    jmp .update_pos
    
.is_ident:
    mov rax, [rbp-24]
    mov byte [rax + token.type], TOKEN_IDENT
    mov [rax + token.value], r8
    
.update_pos:
    mov [rbp-16], r9
    jmp .done

.parse_equal:
    mov rax, [rbp-24]
    mov byte [rax + token.type], TOKEN_EQUAL
    inc rcx
    mov [rbp-16], rcx
    jmp .done

.parse_plus:
    mov rax, [rbp-24]
    mov byte [rax + token.type], TOKEN_PLUS
    inc rcx
    mov [rbp-16], rcx
    jmp .done

.parse_minus:
    mov rax, [rbp-24]
    mov byte [rax + token.type], TOKEN_MINUS
    inc rcx
    mov [rbp-16], rcx
    jmp .done

.parse_multiply:
    mov rax, [rbp-24]
    mov byte [rax + token.type], TOKEN_MULTIPLY
    inc rcx
    mov [rbp-16], rcx
    jmp .done

.parse_divide:
    mov rax, [rbp-24]
    mov byte [rax + token.type], TOKEN_DIVIDE
    inc rcx
    mov [rbp-16], rcx
    jmp .done

.parse_less:
    mov rax, [rbp-24]
    mov byte [rax + token.type], TOKEN_LESS
    inc rcx
    mov [rbp-16], rcx
    jmp .done

.parse_greater:
    mov rax, [rbp-24]
    mov byte [rax + token.type], TOKEN_GREATER
    inc rcx
    mov [rbp-16], rcx
    jmp .done

.check_equal:
    mov rdx, [rbp-8]
    add rdx, rcx
    inc rdx
    movzx r8, byte [rdx]
    cmp r8, '='
    je .parse_equal_equal
    jmp .parse_equal

.parse_equal_equal:
    mov rax, [rbp-24]
    mov byte [rax + token.type], TOKEN_EQUAL_EQUAL
    add rcx, 2
    mov [rbp-16], rcx
    jmp .done

.check_not:
    mov rdx, [rbp-8]
    add rdx, rcx
    inc rdx
    movzx r8, byte [rdx]
    cmp r8, '='
    je .parse_not_equal
    jmp .error

.parse_not_equal:
    mov rax, [rbp-24]
    mov byte [rax + token.type], TOKEN_NOT_EQUAL
    add rcx, 2
    mov [rbp-16], rcx
    jmp .done

.check_and:
    mov rdx, [rbp-8]
    add rdx, rcx
    inc rdx
    movzx r8, byte [rdx]
    cmp r8, '&'
    je .parse_and
    jmp .error

.parse_and:
    mov rax, [rbp-24]
    mov byte [rax + token.type], TOKEN_AND
    add rcx, 2
    mov [rbp-16], rcx
    jmp .done

.check_or:
    mov rdx, [rbp-8]
    add rdx, rcx
    inc rdx
    movzx r8, byte [rdx]
    cmp r8, '|'
    je .parse_or
    jmp .error

.parse_or:
    mov rax, [rbp-24]
    mov byte [rax + token.type], TOKEN_OR
    add rcx, 2
    mov [rbp-16], rcx
    jmp .done

.parse_string:
    ; Парсим строку до следующей "
    mov rdx, [rbp-8]
    add rdx, rcx
    inc rcx  ; пропускаем начальную "
    call parse_string_at
    mov r8, rax  ; string
    mov r9, rdx  ; new position

    mov rax, [rbp-24]
    mov byte [rax + token.type], TOKEN_STRING
    mov [rax + token.value], r8
    mov [rbp-16], r9
    jmp .done

.parse_lparen:
    mov rax, [rbp-24]
    mov byte [rax + token.type], TOKEN_LPAREN
    inc rcx
    mov [rbp-16], rcx
    jmp .done

.parse_rparen:
    mov rax, [rbp-24]
    mov byte [rax + token.type], TOKEN_RPAREN
    inc rcx
    mov [rbp-16], rcx
    jmp .done

.parse_lbrace:
    mov rax, [rbp-24]
    mov byte [rax + token.type], TOKEN_LBRACE
    inc rcx
    mov [rbp-16], rcx
    jmp .done

.parse_rbrace:
    mov rax, [rbp-24]
    mov byte [rax + token.type], TOKEN_RBRACE
    inc rcx
    mov [rbp-16], rcx
    jmp .done

.eof:
    mov rax, [rbp-24]
    mov byte [rax + token.type], TOKEN_EOF
    jmp .done

.error:
    ; Обработка ошибки
    mov rax, 0
    
.done:
    mov rax, [rbp-24]   ; возвращаем токен
    mov rsi, [rbp-16]   ; новую позицию
    leave
    ret

; Вспомогательные функции
parse_integer_at:
    ; rdx = указатель на строку
    ; Возвращает: rax = число, rdx = новая позиция
    xor rax, rax
    xor rcx, rcx
    
.loop:
    movzx r8, byte [rdx + rcx]
    cmp r8b, '0'
    jl .end
    cmp r8b, '9'
    jg .end
    
    sub r8b, '0'
    imul rax, 10
    add rax, r8
    inc rcx
    jmp .loop
    
.end:
    add rdx, rcx
    ret

parse_identifier_at:
    ; rdx = указатель
    ; Возвращает: rax = указатель на строку, rdx = новая позиция
    mov rsi, rdx
    xor rcx, rcx
    
.id_loop:
    movzx r8, byte [rsi + rcx]
    
    ; Проверяем допустимые символы
    cmp r8b, 'a'
    jl .check_upper
    cmp r8b, 'z'
    jle .next_id_char
    
.check_upper:
    cmp r8b, 'A'
    jl .check_digit
    cmp r8b, 'Z'
    jle .next_id_char
    
.check_digit:
    cmp rcx, 0
    je .end_id  ; первая цифра не может быть
    cmp r8b, '0'
    jl .end_id
    cmp r8b, '9'
    jg .end_id
    
.next_id_char:
    inc rcx
    jmp .id_loop
    
.end_id:
    ; Копируем идентификатор
    mov rdi, rcx
    inc rdi  ; +1 для null terminator
    call malloc
    mov r9, rax  ; destination
    
    ; Копируем байты
    xor r10, r10
.copy_loop:
    cmp r10, rcx
    je .copy_done
    mov r8b, [rsi + r10]
    mov [r9 + r10], r8b
    inc r10
    jmp .copy_loop
    
.copy_done:
    mov byte [r9 + r10], 0
    mov rax, r9  ; возвращаем указатель
    add rdx, rcx ; новая позиция
    ret

parse_string_at:
    ; rdx = указатель на начало строки (после ")
    ; Возвращает: rax = указатель на строку, rdx = новая позиция
    mov rsi, rdx
    xor rcx, rcx

.string_loop:
    movzx r8, byte [rsi + rcx]
    cmp r8b, '"'
    je .end_string
    cmp r8b, 0  ; конец файла без закрывающей "
    je .end_string
    inc rcx
    jmp .string_loop

.end_string:
    ; Копируем строку
    mov rdi, rcx
    inc rdi  ; +1 для null
    call malloc
    mov r9, rax  ; destination

    xor r10, r10
.copy_string:
    cmp r10, rcx
    je .string_done
    mov r8b, [rsi + r10]
    mov [r9 + r10], r8b
    inc r10
    jmp .copy_string

.string_done:
    mov byte [r9 + r10], 0
    mov rax, r9  ; возвращаем указатель
    add rdx, rcx ; позиция после строки
    inc rdx  ; пропускаем закрывающую "
    ret

is_keyword:
    ; r8 = строка
    ; Возвращает тип токена или 0 если не ключевое слово
    ; Сравниваем с "let"
    mov rsi, keyword_let
    call strcmp
    cmp rax, 0
    jne .check_print
    mov rax, TOKEN_LET
    ret

.check_print:
    mov rsi, keyword_print
    call strcmp
    cmp rax, 0
    jne .check_if
    mov rax, TOKEN_PRINT
    ret

.check_if:
    mov rsi, keyword_if
    call strcmp
    cmp rax, 0
    jne .check_else
    mov rax, TOKEN_IF
    ret

.check_else:
    mov rsi, keyword_else
    call strcmp
    cmp rax, 0
    jne .check_elif
    mov rax, TOKEN_ELSE
    ret

.check_elif:
    mov rsi, keyword_elif
    call strcmp
    cmp rax, 0
    jne .check_while
    mov rax, TOKEN_ELIF
    ret

.check_while:
    mov rsi, keyword_while
    call strcmp
    cmp rax, 0
    jne .check_do
    mov rax, TOKEN_WHILE
    ret

.check_do:
    mov rsi, keyword_do
    call strcmp
    cmp rax, 0
    jne .check_int
    mov rax, TOKEN_DO
    ret

.check_int:
    mov rsi, keyword_int
    call strcmp
    cmp rax, 0
    jne .check_string
    mov rax, TOKEN_INT
    ret

.check_string:
    mov rsi, keyword_string
    call strcmp
    cmp rax, 0
    jne .check_bool
    mov rax, TOKEN_STRING_TYPE
    ret

.check_bool:
    mov rsi, keyword_bool
    call strcmp
    cmp rax, 0
    jne .check_func
    mov rax, TOKEN_BOOL
    ret

.check_func:
    mov rsi, keyword_func
    call strcmp
    cmp rax, 0
    jne .check_return
    mov rax, TOKEN_FUNC
    ret

.check_return:
    mov rsi, keyword_return
    call strcmp
    cmp rax, 0
    jne .check_int8
    mov rax, TOKEN_RETURN
    ret

.check_int8:
    mov rsi, keyword_int8
    call strcmp
    cmp rax, 0
    jne .check_uint8
    mov rax, TOKEN_INT8
    ret

.check_uint8:
    mov rsi, keyword_uint8
    call strcmp
    cmp rax, 0
    jne .check_int16
    mov rax, TOKEN_UINT8
    ret

.check_int16:
    mov rsi, keyword_int16
    call strcmp
    cmp rax, 0
    jne .check_uint16
    mov rax, TOKEN_INT16
    ret

.check_uint16:
    mov rsi, keyword_uint16
    call strcmp
    cmp rax, 0
    jne .check_int32
    mov rax, TOKEN_UINT16
    ret

.check_int32:
    mov rsi, keyword_int32
    call strcmp
    cmp rax, 0
    jne .check_uint32
    mov rax, TOKEN_INT32
    ret

.check_uint32:
    mov rsi, keyword_uint32
    call strcmp
    cmp rax, 0
    jne .check_int64
    mov rax, TOKEN_UINT32
    ret

.check_int64:
    mov rsi, keyword_int64
    call strcmp
    cmp rax, 0
    jne .check_uint64
    mov rax, TOKEN_INT64
    ret

.check_uint64:
    mov rsi, keyword_uint64
    call strcmp
    cmp rax, 0
    jne .check_int128
    mov rax, TOKEN_UINT64
    ret

.check_int128:
    mov rsi, keyword_int128
    call strcmp
    cmp rax, 0
    jne .check_uint128
    mov rax, TOKEN_INT128
    ret

.check_uint128:
    mov rsi, keyword_uint128
    call strcmp
    cmp rax, 0
    jne .check_bool_type
    mov rax, TOKEN_UINT128
    ret

.check_bool_type:
    mov rsi, keyword_bool
    call strcmp
    cmp rax, 0
    jne .check_func
    mov rax, TOKEN_BOOL
    ret

.check_float16:
    mov rsi, keyword_float16
    call strcmp
    cmp rax, 0
    jne .check_float32
    mov rax, TOKEN_FLOAT16
    ret

.check_float32:
    mov rsi, keyword_float32
    call strcmp
    cmp rax, 0
    jne .check_float64
    mov rax, TOKEN_FLOAT32
    ret

.check_float64:
    mov rsi, keyword_float64
    call strcmp
    cmp rax, 0
    jne .check_try
    mov rax, TOKEN_FLOAT64
    ret

.check_try:
    mov rsi, keyword_try
    call strcmp
    cmp rax, 0
    jne .check_catch
    mov rax, TOKEN_TRY
    ret

.check_catch:
    mov rsi, keyword_catch
    call strcmp
    cmp rax, 0
    jne .check_except
    mov rax, TOKEN_CATCH
    ret

.check_except:
    mov rsi, keyword_except
    call strcmp
    cmp rax, 0
    jne .check_throw
    mov rax, TOKEN_EXCEPT
    ret

.check_throw:
    mov rsi, keyword_throw
    call strcmp
    cmp rax, 0
    jne .check_as
    mov rax, TOKEN_THROW
    ret

.check_as:
    mov rsi, keyword_as
    call strcmp
    cmp rax, 0
    jne .not_keyword
    mov rax, TOKEN_AS
    ret

.not_keyword:
    xor rax, rax
    ret

section .data
keyword_let:   db "let", 0
keyword_print: db "print", 0
keyword_if:    db "if", 0
keyword_else:  db "else", 0
keyword_while: db "while", 0
keyword_do:    db "do", 0
keyword_int:   db "int", 0
keyword_string: db "string", 0
keyword_bool:  db "bool", 0
keyword_func:  db "func", 0
keyword_return: db "return", 0
keyword_int8:  db "Int8", 0
keyword_uint8: db "UInt8", 0
keyword_int16: db "Int16", 0
keyword_uint16: db "UInt16", 0
keyword_int32: db "Int32", 0
keyword_uint32: db "UInt32", 0
keyword_int64: db "Int64", 0
keyword_uint64: db "UInt64", 0
keyword_int128: db "Int128", 0
keyword_uint128: db "UInt128", 0
keyword_float16: db "Float16", 0
keyword_float32: db "Float32", 0
keyword_float64: db "Float64", 0
keyword_try: db "try", 0
keyword_catch: db "catch", 0
keyword_except: db "except", 0
keyword_throw: db "throw", 0
keyword_as: db "as", 0
keyword_elif: db "elif", 0

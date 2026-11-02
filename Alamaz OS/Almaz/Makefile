# Makefile
ASM = nasm
ASMFLAGS = -f elf64
CC = gcc
CFLAGS = -no-pie -nostartfiles

all: mylang_compiler

mylang_compiler: main.o lexer.o parser.o codegen.o stdlib.o
	$(CC) $(CFLAGS) $^ -o $@

main.o: src/compiler/main.asm
	$(ASM) $(ASMFLAGS) $< -o $@

lexer.o: src/lexer/lexer.asm
	$(ASM) $(ASMFLAGS) $< -o $@

parser.o: src/parser/parser.asm
	$(ASM) $(ASMFLAGS) $< -o $@

codegen.o: src/compiler/codegen.asm
	$(ASM) $(ASMFLAGS) $< -o $@

stdlib.o: src/stdlib/stdlib.asm
	$(ASM) $(ASMFLAGS) $< -o $@

run: mylang_compiler
	./mylang_compiler
	nasm -f elf64 output.asm -o output.o
	ld -m elf_x86_64 output.o -o output
	./output

clean:
	rm -f *.o mylang_compiler output.asm output output.o

.PHONY: all run clean

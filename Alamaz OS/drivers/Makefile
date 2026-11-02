# Makefile для драйверов

ASM = nasm
CFLAGS = -f elf64

all: drivers.o

drivers.o: keyboard.o vga.o
    ld -r $^ -o drivers.o

keyboard.o: keyboard.alm
    alm-compiler keyboard.alm -o keyboard.o

vga.o: vga.alm
    alm-compiler vga.alm -o vga.o

clean:
    rm -f *.o
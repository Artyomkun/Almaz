
## 🔧 **Простой Makefile**

```make
# Makefile для ядра

ASM = almazc
LD = ld
QEMU = qemu-system-x86_64

CFLAGS = -f elf64
LDFLAGS = -T linker.ld

OBJS = boot/boot.o \
       boot/gdt.o \
       boot/idt.o \
       memory/paging.o \
       memory/heap.o \
       dev/console.o

all: kernel.bin

kernel.bin: $(OBJS)
	$(LD) $(LDFLAGS) -o $@ $^

%.o: %.alm
	$(ASM) $(CFLAGS) -c $< -o $@

run: kernel.bin
	$(QEMU) -kernel kernel.bin

debug: kernel.bin
	$(QEMU) -s -S -kernel kernel.bin

clean:
	rm -f $(OBJS) kernel.bin

.PHONY: all run debug clean
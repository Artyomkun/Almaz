all: bootloader.bin

stage1.bin: stage1.alm
	almazc -f bin -Ttext=0x7C00 -o $@ $<  # ровно 512 байт!

stage2.bin: stage2.alm fat32.alm elf.alm
	almazc -f elf -o stage2.elf $^
	objcopy -O binary stage2.elf stage2.bin

bootloader.bin: stage1.bin stage2.bin
	cat stage1.bin stage2.bin > $@
	# stage1 (512 байт) + stage2 (остальное)
# Almaz OS — Загрузчик

Этот каталог содержит загрузчик для Almaz OS. Он отвечает за переход от включения питания до запуска ядра.

## 📁 Структура

```text
bootloader/
├── README.md                    # документация загрузчика
├── Makefile                      # сборка
├── stage1.alm                   #  ТОЧКА ВХОДА сектор 0
├── stage2.alm                   #  ТОЧКА ВХОДА сектор 1
├── multiboot.alm                #  ТОЧКА ВХОДА Multiboot
├── stage1/                       # сектор 0
│   ├── boot.alm                   # 512 байт, MBR
│   ├── print.alm                   # вывод на экран
│   └── disk.alm                    # чтение с диска
│
├── stage2/                       # сектор 1
│   ├── main.alm                    # вход на Almaz!
│   ├── fat32.alm                    # чтение FAT32
│   ├── elf.alm                      # загрузка ELF
│   ├── memory.alm                   # определение памяти
│   ├── video.alm                    # переключение в VESA
│   ├── keyboard.alm                  # ввод
│   └── loader.alm                    # загрузка ядра
│
├── multiboot/                    # поддержка Multiboot
│   ├── header.alm                  # Multiboot заголовок
│   └── entry.alm                   # точка входа
│
├── iso/                          # создание ISO образа
│   ├── isolinux.cfg
│   └── mkiso.sh
│
└── test/                         # тесты
    └── run_qemu.sh                 # запуск в QEMU
```

## 🚀 Статус разработки

| Компонент | Статус  | Описание                     |
|-----------|---------|------------------------------|
| stage1    | ⚪ План | MBR, чтение stage2           |
| stage2    | ⚪ План | Основной загрузчик на Almaz! |
| FAT32     | ⚪ План | Чтение файлов с диска        |
| ELF loader| ⚪ План | Загрузка ядра в память       |
| VESA      | ⚪ План | Графический режим            |
| Multiboot | ⚪ План | Совместимость с GRUB         |

## 🔧 Сборка

```bash
# Собрать MBR (stage1)
make stage1

# Собрать stage2 (на Almaz!)
make stage2

# Собрать полный образ
make bootloader.bin

# Создать ISO
make iso

# Запустить в QEMU
make run
```

## 📝 Пример stage2 на Almaz

```assembly
; stage2/main.alm — вход на Almaz!
import fat32
import elf
import vesa

func main() {
    // инициализация
    init_video()
    print("Almaz OS Loader v0.1\n")
    
    // поиск ядра на диске
    kernel_file = fat32_open("/kernel.bin")
    if kernel_file == 0 {
        print("Kernel not found!\n")
        halt()
    }
    
    // загрузка ELF
    entry = elf_load(kernel_file)
    print("Kernel loaded at ")
    print_hex(entry)
    print("\n")
    
    // запуск ядра
    jump_to(entry)
}
```

## 🔥 Этапы загрузки

```text
1. BIOS → stage1 (MBR)
        ↓
2. stage1 → stage2 (секторы 1-...)
        ↓
3. stage2 (Almaz!) ищет kernel.bin
        ↓
4. stage2 загружает ядро в память
        ↓
5. Переход на kernel_main()
        ↓
6. ALMAZ OS ЗАПУЩЕНА! 🚀
```

## 🎯 Цели

- [ ] MBR (первые 512 байт)

- [ ] Переход в защищённый режим

- [ ] Чтение FAT32

- [ ] Загрузка ELF

- [ ] Переключение в VESA

- [ ] Запуск ядра

## 📞 Контакты

Артём — автор Almaz OS  
GitHub: @Artyomkun  
SourceCraft: /selemetartem-gmail-com

---

**Almaz OS** — новый язык, новая ОС, новое будущее. 🚀

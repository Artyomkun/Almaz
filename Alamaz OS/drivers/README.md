# Almaz OS — Драйверы устройств

Этот каталог содержит драйверы для Almaz OS — новой операционной системы,
написанной на собственном языке программирования Almaz.

## 📁 Структура драйверов

drivers/
├── keyboard/ # Драйвер клавиатуры
├── mouse/ # Драйвер мыши
├── display/ # Видео/дисплей (VGA, framebuffer)
├── storage/ # Диски (AHCI, SATA, NVMe)
├── filesystems/ # Файловые системы (ext2, fat32, almazfs)
├── network/ # Сеть (RTL8139, e1000, TCP/IP)
├── audio/ # Звук (AC97, HDA)
├── usb/ # USB контроллеры (UHCI, OHCI, EHCI, xHCI)
├── pci/ # PCI шина
├── power/ # Управление питанием (ACPI)
└── misc/ # RTC, CMOS, COM-порты

text

## 🚀 Статус разработки

| Драйвер  | Статус           | Заметки          |
|----------|------------------|------------------|
| keyboard | 🟡 В разработке  | Базовый PS/2     |
| vga      | 🟡 В разработке  | Text mode 80x25  |
| ...      | ⚪ План          |                  |

## 🔧 Как собрать

```bash
make all          # собрать все драйверы
make keyboard.o   # собрать конкретный драйвер
make clean        # очистить
```

## 📝 Язык Almaz

Драйверы пишутся на Almaz — собственном языке программирования,
специально разработанном для системного программирования.

```assembly
; Пример драйвера на Almaz
func keyboard_handler() {
    scancode = inb(0x60)
    key = translate(scancode)
    push_to_buffer(key)
}
```

## 🎯 Цель

Сделать Almaz OS полностью самодостаточной —
от загрузчика до графического интерфейса,
написанной на одном языке.

## 📞 Контакты

Артём — автор Almaz OS  
GitHub: @Artyomkun  
SourceCraft: /selemetartem-gmail-com

---

**Almaz** — новый язык. 🚀

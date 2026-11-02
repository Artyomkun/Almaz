# Almaz OS — Ядро

Этот каталог содержит ядро Almaz OS — операционной системы, написанной на собственном языке программирования Almaz.

## 📁 Структура

```text
kernel/
├── README.md                     # документация ядра
├── Makefile                      # сборка ядра
├── boot.alm                      # загрузка
├── dev.alm                       # устройства
├── ipc.alm                       # IPC
├── memory.alm                    # память
├── process.alm                   # процессы
├── sync.alm                      # синхронизация
├── time.alm                      # время
├── boot/                         # загрузка
│   ├── boot.alm                   # точка входа (start)
│   ├── multiboot.alm              # Multiboot заголовок (для GRUB)
│   ├── gdt.alm                     # Глобальная таблица дескрипторов
│   ├── idt.alm                     # Таблица прерываний
│   └── interrupts.alm              # обработчики прерываний
│
├── memory/                        # управление памятью
│   ├── paging.alm                  # страничная память
│   ├── heap.alm                     # куча (malloc/free)
│   ├── physmem.alm                  # физическая память
│   └── vmm.alm                      # виртуальная память
│
├── process/                       # процессы
│   ├── scheduler.alm                # планировщик
│   ├── task.alm                     # структура задачи
│   ├── switch.alm                    # переключение контекста
│   └── syscall.alm                   # системные вызовы
│
├── sync/                          # синхронизация
│   ├── spinlock.alm                 # спин-блокировки
│   ├── mutex.alm                     # мьютексы
│   └── semaphore.alm                 # семафоры
│
├── time/                          # время
│   ├── timer.alm                    # PIT/APIC таймер
│   ├── sleep.alm                     # sleep/usleep
│   └── clock.alm                     # системное время
│
├── dev/                           # встроенные устройства
│   ├── console.alm                  # вывод на экран
│   ├── keyboard.alm                  # клавиатура (ранний драйвер)
│   ├── serial.alm                    # COM-порты (отладка)
│   └── pci.alm                       # PCI сканирование
│
├── ipc/                           # межпроцессное взаимодействие
│   ├── pipe.alm                      # каналы
│   ├── shmem.alm                     # разделяемая память
│   └── signal.alm                    # сигналы
│
└── test/                          # тесты ядра
    ├── test_memory.alm
    ├── test_sched.alm
    └── test_sync.alm

```

## 🚀 Статус разработки

| Компонент  | Статус  | Описание                |
|------------|---------|-------------------------|
| boot       | ⚪ План | Загрузчик и вход в ядро |
| GDT/IDT    | ⚪ План | Таблицы дескрипторов    |
| interrupts | ⚪ План | Обработка прерываний    |
| paging     | ⚪ План | Страничная память       |
| heap       | ⚪ План | malloc/free             |
| scheduler  | ⚪ План | Планировщик задач       |
| syscalls   | ⚪ План | Системные вызовы        |
| console    | ⚪ План | Вывод на экран          |

## 🔧 Сборка

```bash
# Собрать ядро
make all

# Собрать в ISO (для загрузки)
make iso

# Запустить в QEMU
make run

# Отладка
make debug
```

📝 Точка входа (boot.alm)

```assembly
; boot.alm — точка входа ядра
section .text
global _start

_start:
    ; очистка экрана
    call clear_screen
    
    ; инициализация GDT/IDT
    call init_gdt
    call init_idt
    
    ; включение страничной памяти
    call init_paging
    
    ; инициализация таймера
    call init_timer
    
    ; переход в основной цикл
    call kernel_main
```

🎯 Цели

- [ ] Multiboot-совместимость

- [ ] Защищённый режим

- [ ] Страничная память

- [ ] Планировщик задач

- [ ] Системные вызовы

- [ ] Многозадачность

- [ ] Модульное тестирование

🔥 Пример (ранний вывод)

```assembly
; console.alm — простой вывод
func putchar(c: int) {
    // VGA text mode (0xB8000)
    vga_buffer = 0xB8000
    vga_buffer[cursor_pos] = c
    vga_buffer[cursor_pos+1] = 0x07
    cursor_pos += 2
}
```

📞 Контакты
Артём — автор Almaz OS
GitHub: @Artyomkun
SourceCraft: /selemetartem-gmail-com

**Almaz OS** — новый язык, новая ОС, новое будущее. 🚀

# Almaz OS — Файловая система

Этот каталог содержит реализацию файловой системы для Almaz OS — новой операционной системы, написанной на собственном языке программирования Almaz.

## 📁 Структура

```text
fs/
├── vfs.alm         # Виртуальная файловая система (VFS)
├── almazfs.alm     # Родная файловая система Almaz OS
├── devfs.alm       # Файловая система устройств (/dev)
├── procfs.alm      # Файловая система процессов (/proc)
├── tmpfs.alm       # Временная ФС в памяти (tmpfs)
├── README.md                    # что тут вообще происходит
├── Makefile                      # сборка файловой системы
│
├── vfs/                          # виртуальная файловая система (VFS)
│   ├── vfs.alm                    # основной слой абстракции
│   ├── file.alm                    # работа с файлами
│   ├── dir.alm                     # работа с директориями
│   └── mount.alm                   # монтирование разделов
│
├── almazfs/                      # собственная ФС для Almaz OS
│   ├── almazfs.alm                 # основная реализация
│   ├── superblock.alm              # суперблок
│   ├── inode.alm                   # inode
│   ├── dir.alm                     # директории
│   ├── block.alm                    # управление блоками
│   └── mkfs.almazfs.alm            # создание ФС
│
├── ext2/                          # поддержка ext2/3/4
│   ├── ext2.alm
│   ├── ext2_superblock.alm
│   ├── ext2_inode.alm
│   └── ext2_dir.alm
│
├── fat32/                         # поддержка FAT32
│   ├── fat32.alm
│   ├── fat32_bpb.alm              # BIOS Parameter Block
│   ├── fat32_dir.alm               # директории FAT
│   └── fat32_file.alm              # файлы FAT
│
├── devfs/                         # файловая система устройств (/dev)
│   ├── devfs.alm
│   ├── device.alm                   # абстракция устройств
│   └── nodes.alm                    # /dev/null, /dev/zero и т.д.
│
├── procfs/                        # файловая система процессов (/proc)
│   ├── procfs.alm
│   ├── process.alm                  # информация о процессах
│   └── sysinfo.alm                  # системная информация
│
└── tmpfs/                          # временная ФС в памяти
    ├── tmpfs.alm
    └── page.alm                     # управление страницами
```

## 🚀 Статус разработки

| Компонент | Статус  | Описание                          |
|-----------|---------|-----------------------------------|
| VFS       | ⚪ План | Абстрактный слой для всех ФС      |
| almazfs   | ⚪ План | Собственная ФС Almaz OS           |
| devfs     | ⚪ План | /dev/null, /dev/zero, /dev/random |
| procfs    | ⚪ План | /proc — информация о процессах    |
| tmpfs     | ⚪ План | Временные файлы в RAM             |
| ext2      | ⚪ План | Поддержка Linux-совместимых ФС    |
| fat32     | ⚪ План | Совместимость с Windows/USB       |

## 🔧 Сборка

```bash
# Собрать всё
make all

# Собрать только VFS
make vfs

# Собрать конкретный компонент
make almazfs.o

# Очистить
make clean

# Информация о сборке
make info
```

## 📝 Интерфейс VFS (план)

```c
// Открытие файла
func vfs_open(path: str, flags: int) -> int

// Чтение из файла
func vfs_read(fd: int, buf: ptr, size: int) -> int

// Запись в файл
func vfs_write(fd: int, buf: ptr, size: int) -> int

// Закрытие файла
func vfs_close(fd: int) -> int

// Создание директории
func vfs_mkdir(path: str, mode: int) -> int

// Удаление файла
func vfs_unlink(path: str) -> int
```

## 🎯 Пример использования

```assembly
; Пример открытия файла на Almaz
import vfs

func main() {
    fd = vfs_open("/dev/null", O_RDWR)
    if fd >= 0 {
        vfs_write(fd, "hello", 5)
        vfs_close(fd)
    }
}
```

## 📊 Планы

- [x] Структура каталогов
- [ ] Базовая VFS
- [ ] devfs с /dev/null
- [ ] almazfs — своя ФС
- [ ] Поддержка ext2
- [ ] Монтирование разделов

## 🧪 Тестирование

```bash
make test
```

Запустит тесты для проверки работы файловой системы.

## 📞 Контакты

Артём — автор Almaz OS  
GitHub: @Artyomkun  
SourceCraft: /selemetartem-gmail-com

---

**Almaz OS** — новый язык, новая ОС, новое будущее. 🚀

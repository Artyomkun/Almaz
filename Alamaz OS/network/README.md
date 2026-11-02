# Almaz OS — Сетевой стек

Этот каталог содержит реализацию сетевого стека для Almaz OS.

## 📁 Структура

```text
network/
├── README.md                    # документация сетевого стека
├── Makefile                      # сборка сетевых компонентов
├── core.alm                      # ядро
├── ip.alm                        # IP протоколы
├── transport.alm                 # TCP/UDP
├── socket.alm                    # API сокетов
├── dns.alm                       # DNS резолвер
├── routing.alm                   # маршрутизация
├── firewall.alm                  # сетевой экран
├── drivers.alm                   # драйверы
├── ppp.alm                       # PPP
├── core/                         # ядро сетевого стека
│   ├── net.alm                    # основной сетевой интерфейс
│   ├── buffer.alm                  # сетевые буферы
│   ├── sk_buff.alm                 # socket buffers (как в Linux)
│   └── interface.alm               # сетевые интерфейсы
│
├── drivers/                       # драйверы сетевых карт
│   ├── rtl8139.alm                 # Realtek RTL8139
│   ├── e1000.alm                   # Intel PRO/1000
│   ├── virtio-net.alm              # VirtIO (для виртуалок)
│   └── loopback.alm                 # локальная петля (lo)
│
├── ip/                            # IP протоколы
│   ├── ipv4.alm                    # IPv4
│   ├── ipv6.alm                    # IPv6 (на будущее)
│   ├── icmp.alm                    # ICMP (ping)
│   ├── arp.alm                     # ARP (адреса)
│   └── checksum.alm                # контрольные суммы
│
├── transport/                     # транспортный уровень
│   ├── tcp.alm                     # TCP протокол
│   ├── udp.alm                     # UDP протокол
│   ├── tcp_congestion.alm          # управление перегрузкой
│   └── tcp_timers.alm              # таймеры TCP
│
├── socket/                        # сокеты (API для программ)
│   ├── socket.alm                  # sys_socket, sys_bind, etc
│   ├── sock.alm                    # структура сокета
│   ├── af_inet.alm                 # Address Family INET
│   └── netlink.alm                 # Netlink (общение с ядром)
│
├── dns/                           # DNS резолвер
│   ├── dns.alm                     # простой DNS клиент
│   └── resolver.alm                 # резолвер имен
│
├── routing/                       # маршрутизация
│   ├── route.alm                   # таблица маршрутизации
│   ├── fib.alm                     # Forwarding Information Base
│   └── neigh.alm                   # соседи (ARP кеш)
│
├── firewall/                      # сетевой экран
│   ├── iptables.alm                # правила фильтрации
│   ├── filter.alm                  # фильтр пакетов
│   └── nat.alm                     # Network Address Translation
│
├── ppp/                           # PPP (для модемов)
│   ├── ppp.alm
│   └── pppoe.alm
│
└── test/                          # тесты
    ├── test_tcp.alm
    ├── test_udp.alm
    └── test_ping.alm
```

## 🚀 Статус разработки

| Компонент  | Статус  | Описание                       |
|------------|---------|--------------------------------|
| loopback   | ⚪ План | lo интерфейс                   |
| ARP        | ⚪ План | Протокол разрешения адресов    |
| IPv4       | ⚪ План | Базовая отправка/прием пакетов |
| ICMP       | ⚪ План | Ping                           |
| UDP        | ⚪ План | User Datagram Protocol         |
| TCP        | ⚪ План | Transmission Control Protocol  |
| socket API | ⚪ План | Беркли сокеты                  |
| DHCP       | ⚪ План | Получение IP автоматически     |
| DNS        | ⚪ План | Резолвер имен                  |
| драйверы   | ⚪ План | RTL8139, e1000, virtio         |

## 🔧 Сборка

```bash
# Собрать всё
make all

# Собрать только TCP/IP
make tcp_ip

# Собрать драйвер
make rtl8139.o

# Очистить
make clean
```

📝 Пример использования (план)

```cxx
// Простой HTTP клиент на Almaz
import socket

func main() {
    sock = socket(AF_INET, SOCK_STREAM, 0)
    addr = sockaddr_in(80, "93.184.216.34")  // example.com
    connect(sock, addr)
    
    send(sock, "GET / HTTP/1.0\r\n\r\n")
    recv(sock, buffer, 1024)
    print(buffer)
    
    close(sock)
}
```

## 📊 Планы

- [ ] loopback интерфейс

- [ ] ARP

- [ ] IPv4

- [ ] ICMP (ping)

- [ ] UDP

- [ ] TCP базовый

- [ ] socket API

- [ ] DHCP клиент

- [ ] DNS резолвер

- [ ] Драйвер RTL8139

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

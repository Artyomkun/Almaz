ASM = almazc
TARGET = network.o

OBJS = core/net.o \
       ip/ipv4.o \
       ip/icmp.o \
       ip/arp.o \
       transport/udp.o \
       drivers/loopback.o

all: $(TARGET)

$(TARGET): $(OBJS)
	ld -r $^ -o $@

%.o: %.alm
	$(ASM) -f elf64 $< -o $@

clean:
	rm -f $(OBJS) $(TARGET)

.PHONY: all clean
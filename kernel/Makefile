# Makefile for kernel
# Modified for TCC compilation

# Directories
u = /usr
i = $u/include
l = $u/lib
s = system

# Programs, flags, etc.
CC ?= tcc
AS ?= as
LD ?= ld
CFLAGS = -m32 -I$i -I../include -D_MINIX -D_SYSTEM -D_KERNEL \
         -fno-builtin -fno-stack-protector
ASFLAGS = --32
LDFLAGS = -m elf_i386 -nostdlib -Ttext 0x00100000

HEAD = mpx.o

OBJS = start.o protect.o klib.o table.o main.o proc.o \
       i8259.o exception.o system.o clock.o utility.o

SYSTEM = system.a

LIBS = -ltimers

# What to make.
all: build

kernel build: $(HEAD) $(OBJS) $(SYSTEM)
	$(LD) $(LDFLAGS) -o kernel \
		$(HEAD) $(OBJS) \
		$(SYSTEM) $(LIBS)

install: kernel
	install -o root -c kernel /boot/kernel

$(SYSTEM):
	cd system && $(MAKE) -$(MAKEFLAGS) build

clean:
	cd system && $(MAKE) -$(MAKEFLAGS) $@
	rm -f *.a *.o *~ *.bak kernel

depend:
	@echo "Dependencies updated for TCC build"

# Assembly files for i386
mpx.o: mpx386.s
	$(AS) $(ASFLAGS) mpx386.s -o mpx.o

klib.o: klib386.s
	$(AS) $(ASFLAGS) klib386.s -o klib.o

# Pattern rule for C files
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

.PHONY: all build install clean depend


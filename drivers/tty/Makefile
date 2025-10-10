# Makefile for terminal driver (TTY)
# Modified for TCC compilation

DRIVER = tty

# directories
u = /usr
i = $u/include
s = $i/sys
m = $i/minix
b = $i/ibm
d = ..

# programs, flags, etc.
MAKE = exec make
CC = tcc
CFLAGS = -m32 -I$i -I../../include -D_MINIX -D_SYSTEM
LDFLAGS = -m32 -nostdlib
LIBS = -ldriver -lsys -lsysutil -ltimers

OBJ = tty.o console.o vidcopy.o keyboard.o

# build local binary
all build: $(DRIVER)

$(DRIVER): $(OBJ)
	$(CC) -o $@ $(LDFLAGS) $(OBJ) $(LIBS)

# install with other drivers
install: /usr/sbin/$(DRIVER)
	cd keymaps && $(MAKE) -$(MAKEFLAGS) install

/usr/sbin/$(DRIVER): $(DRIVER)
	install -o root -c $? $@

# clean up local files
clean:
	cd keymaps && $(MAKE) -$(MAKEFLAGS) $@
	rm -f $(DRIVER) *.o *.bak

depend:
	@echo "Dependencies updated for TCC build"

# Pattern rule for compiling C files
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

.PHONY: all build install clean depend


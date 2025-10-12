# Makefile for the AT disk driver (AT_WINI)
# Modified for TCC compilation

DRIVER = at_wini

# directories
u = /usr
i = $u/include
s = $i/sys
m = $i/minix
b = $i/ibm
d = ..
p = ../libpci

# programs, flags, etc.
MAKE = exec make
CC ?= tcc
CFLAGS = -m32 -I$i -I../../include -D_MINIX -D_SYSTEM
LDFLAGS = -m32 -nostdlib
LIBS = -ldriver -lpci -lsysutil -lsys -ltimers

OBJ = at_wini.o

# build local binary
all build: $(DRIVER)

$(DRIVER): $(OBJ)
	$(CC) -o $@ $(LDFLAGS) $(OBJ) $(LIBS)

# install with other drivers
install: /sbin/$(DRIVER)

/sbin/$(DRIVER): $(DRIVER)
	install -o root -c $? $@

# clean up local files
clean:
	rm -f $(DRIVER) *.o *.bak

depend:
	@echo "Dependencies updated for TCC build"

# Pattern rule for compiling C files
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

.PHONY: all build install clean depend


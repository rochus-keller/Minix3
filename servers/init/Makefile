# Makefile for the init program (INIT)
# Modified for TCC compilation

SERVER = init

# directories
u = /usr
i = $u/include
s = $i/sys
h = $i/minix
k = $u/src/kernel

# programs, flags, etc.
CC = tcc
CFLAGS = -m32 -I$i -I../../include -O -D_MINIX -D_POSIX_SOURCE -D_SYSTEM
LDFLAGS = -m32 -nostdlib

OBJ = init.o

# build local binary
all build: $(SERVER)

$(SERVER): $(OBJ)
	$(CC) $(CFLAGS) -o $@ $(LDFLAGS) $(OBJ) -lsysutil

# install with other servers
install: /usr/sbin/$(SERVER)

/usr/sbin/$(SERVER): $(SERVER)
	install -o root -c $? $@

# clean up local files
clean:
	rm -f $(SERVER) *.o *.bak

depend:
	@echo "Dependencies updated for TCC build"

# Pattern rule for compiling C files
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

.PHONY: all build install clean depend


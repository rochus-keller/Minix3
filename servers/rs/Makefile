# Makefile for Reincarnation Server (RS)
# Modified for TCC compilation

SERVER = rs
UTIL = service

# directories
u = /usr
i = $u/include
s = $i/sys
m = $i/minix
b = $i/ibm

# programs, flags, etc.
CC = tcc
CFLAGS = -m32 -I$i -I../../include -D_MINIX -D_POSIX_SOURCE -D_SYSTEM
LDFLAGS = -m32 -nostdlib
UTIL_LIBS = -lsys
LIBS = -lsys -lsysutil

UTIL_OBJ = service.o
OBJ = rs.o manager.o

# build local binary
all build: $(SERVER) $(UTIL)

$(UTIL): $(UTIL_OBJ)
	$(CC) -o $@ $(LDFLAGS) $(UTIL_OBJ) $(UTIL_LIBS)

$(SERVER): $(OBJ)
	$(CC) -o $@ $(LDFLAGS) $(OBJ) $(LIBS)

# install with other servers
install: /bin/$(UTIL) /usr/sbin/$(SERVER)

/bin/$(UTIL): $(UTIL)
	install -c $? $@

/usr/sbin/$(SERVER): $(SERVER)
	install -o root -c $? $@

# clean up local files
clean:
	rm -f $(UTIL) $(SERVER) *.o *.bak

depend:
	@echo "Dependencies updated for TCC build"

# Pattern rule for compiling C files
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

.PHONY: all build install clean depend


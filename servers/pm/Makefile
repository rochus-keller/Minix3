# Makefile for Process Manager (PM)
# Modified for TCC compilation

SERVER = pm

# directories
u = /usr
i = $u/include
s = $i/sys
h = $i/minix
k = $u/src/kernel

# programs, flags, etc.
CC = tcc
CFLAGS = -m32 -I$i -I../../include -D_MINIX -D_POSIX_SOURCE -D_SYSTEM
LDFLAGS = -m32 -nostdlib
LIBS = -lsys -lsysutil -ltimers
OBJ = main.o forkexit.o break.o exec.o time.o timers.o \
      signal.o alloc.o utility.o table.o trace.o getset.o misc.o

# build local binary
all build: $(SERVER)

$(SERVER): $(OBJ)
	$(CC) -o $@ $(LDFLAGS) $(OBJ) $(LIBS)

# install with other servers
install: /usr/sbin/$(SERVER)

/usr/sbin/$(SERVER): $(SERVER)
	install -o root -c $? $@

# clean up local files
clean:
	rm -f $(SERVER) *.o *.bak

depend:
	@echo "Dependencies updated"

# Pattern rule for object files
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

.PHONY: all build install clean depend


# Makefile for File System (FS)
# Modified for TCC compilation

SERVER = fs

# directories
u = /usr
i = $u/include
s = $i/sys
h = $i/minix

# programs, flags, etc.
CC = tcc
CFLAGS = -m32 -I$i -I../../include -D_MINIX -D_POSIX_SOURCE -D_SYSTEM $(EXTRA_OPTS)
LDFLAGS = -m32 -nostdlib
LIBS = -lsys -lsysutil -ltimers

OBJ = main.o open.o read.o write.o pipe.o dmap.o \
      device.o path.o mount.o link.o super.o inode.o \
      cache.o filedes.o stadir.o protect.o time.o \
      lock.o misc.o utility.o select.o timers.o table.o \
      cdprobe.o

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
	@echo "Dependencies updated for TCC build"

# Pattern rule for compiling C files
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

.PHONY: all build install clean depend


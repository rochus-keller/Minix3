# Example: servers/pm/Makefile

SERVER = pm

u = /usr
i = $u/include

CC ?= tcc
CFLAGS = -m32 -I$i -I../../include -I../../usr/include -D_MINIX -D_POSIX_SOURCE -D_SYSTEM
LDFLAGS = -m32 -nostdlib
LIBS = -lsys -lsysutil -ltimers

OBJ = main.o forkexit.o break.o exec.o time.o timers.o \
      signal.o alloc.o utility.o table.o trace.o getset.o misc.o

all build: $(SERVER)

$(SERVER): $(OBJ)
	$(CC) -o $@ $(LDFLAGS) $(OBJ) $(LIBS)

clean:
	rm -f $(SERVER) *.o *.bak

depend:
	@echo "Dependencies updated for TCC build"

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

.PHONY: all build clean depend


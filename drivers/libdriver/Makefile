# Makefile for driver library
# Modified for TCC compilation

LIBRARY = libdriver.a

# Directories
u = /usr
i = $u/include
s = $i/sys
b = $i/ibm
m = $i/minix

# Programs, flags, etc.
CC = tcc
AR = ar
RANLIB = ranlib
CFLAGS = -m32 -I$i -I../../include -D_MINIX -D_SYSTEM
LDFLAGS = -m32
LIBS = -lsysutil -lsys

OBJECTS = driver.o drvlib.o

all build: $(LIBRARY)

$(LIBRARY): $(OBJECTS)
	$(AR) rcs $@ $(OBJECTS)
	$(RANLIB) $@

install: /usr/lib/$(LIBRARY)

/usr/lib/$(LIBRARY): $(LIBRARY)
	install -c $? $@
	$(RANLIB) $@

clean:
	rm -f $(LIBRARY) *.o *.bak

depend:
	@echo "Dependencies updated for TCC build"

# Pattern rule for compiling C files
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

.PHONY: all build install clean depend


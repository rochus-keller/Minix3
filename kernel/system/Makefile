# Makefile for system library implementation
# Modified for TCC compilation

# Directories
u = /usr
i = $u/include

# Programs, flags, etc.
CC = tcc
AR = ar
RANLIB = ranlib
CFLAGS = -m32 -I$i -I../../include -D_MINIX -D_SYSTEM -D_KERNEL \
         -fno-builtin -fno-stack-protector

SYSTEM = ../system.a

# What to make.
all build: $(SYSTEM)

# System call handler source files
SOURCES = \
	do_unused.c \
	do_fork.c \
	do_exec.c \
	do_newmap.c \
	do_exit.c \
	do_trace.c \
	do_nice.c \
	do_times.c \
	do_setalarm.c \
	do_irqctl.c \
	do_devio.c \
	do_vdevio.c \
	do_int86.c \
	do_sdevio.c \
	do_copy.c \
	do_vcopy.c \
	do_umap.c \
	do_memset.c \
	do_privctl.c \
	do_segctl.c \
	do_getksig.c \
	do_endksig.c \
	do_kill.c \
	do_sigsend.c \
	do_sigreturn.c \
	do_abort.c \
	do_getinfo.c \

OBJECTS = $(SOURCES:.c=.o)

$(SYSTEM): $(OBJECTS)
	$(AR) rcs $@ $(OBJECTS)
	$(RANLIB) $@

install: $(SYSTEM)
	@echo "System call handlers built into $(SYSTEM)"

clean:
	rm -f $(SYSTEM) *.o *~ *.bak

depend:
	@echo "Dependencies updated for TCC build"

# Pattern rule for compiling C files
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

.PHONY: all build install clean depend


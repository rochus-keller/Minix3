# Makefile for all device drivers.
# Modified for TCC compilation

MAKE = exec make -$(MAKEFLAGS)
CC ?= tcc
EXTRA_OPTS = -m32 -D_MINIX -D_SYSTEM

export CC EXTRA_OPTS

usage:
	@echo "" >&2
	@echo "Makefile for all device drivers." >&2
	@echo "Usage:" >&2
	@echo "	make build    # Compile all device drivers locally" >&2
	@echo "	make image    # Compile drivers in boot image" >&2
	@echo "	make clean    # Remove local compiler results" >&2
	@echo "	make install  # Install drivers to /sbin/" >&2
	@echo "	                (requires root privileges)" >&2
	@echo "" >&2

build: all

all install depend clean:
	cd ./libdriver && $(MAKE) $@
	cd ./libpci && $(MAKE) $@
	cd ./tty && $(MAKE) $@
	cd ./memory && $(MAKE) $@
	cd ./at_wini && $(MAKE) $@
	cd ./log && $(MAKE) $@

image:
	cd ./libdriver && $(MAKE) build
	cd ./libpci && $(MAKE) build
	cd ./tty && $(MAKE) build
	cd ./memory && $(MAKE) build
	cd ./at_wini && $(MAKE) build
	cd ./log && $(MAKE) build

.PHONY: usage build all install depend clean image


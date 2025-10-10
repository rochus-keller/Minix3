# Makefile for all system servers.
# Modified for TCC compilation

MAKE = exec make -$(MAKEFLAGS)
CC = tcc
EXTRA_OPTS = -m32 -D_MINIX -D_POSIX_SOURCE

export CC EXTRA_OPTS

usage:
	@echo "" >&2
	@echo "Makefile for all system servers." >&2
	@echo "Usage:" >&2
	@echo "	make build    # Compile all system servers locally" >&2
	@echo "	make image    # Compile servers in boot image" >&2
	@echo "	make clean    # Remove local compiler results" >&2
	@echo "	make install  # Install servers to /usr/sbin/" >&2
	@echo "	                (requires root privileges)" >&2
	@echo "" >&2

build: all

all install depend clean:
	cd ./pm && $(MAKE) $@
	cd ./fs && $(MAKE) $@
	cd ./rs && $(MAKE) $@
	cd ./init && $(MAKE) $@

image:
	cd ./pm && $(MAKE) EXTRA_OPTS=$(EXTRA_OPTS) build
	cd ./fs && $(MAKE) EXTRA_OPTS=$(EXTRA_OPTS) build
	cd ./rs && $(MAKE) EXTRA_OPTS=$(EXTRA_OPTS) build
	cd ./init && $(MAKE) EXTRA_OPTS=$(EXTRA_OPTS) build

.PHONY: usage build all install depend clean image


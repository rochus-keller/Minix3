# Top-level Makefile for Minix 3

.PHONY: all build clean headers libs kernel servers drivers

all: build

build: headers libs kernel servers drivers

# Phase 1: Headers
headers:
	@echo "Installing headers..."
	cd include && $(MAKE) install-local

# Phase 2: Libraries
libs:
	@echo "Building libraries..."
	cd drivers/libdriver && $(MAKE) build
	cd drivers/libpci && $(MAKE) build

# Phase 3: Kernel
kernel: libs
	@echo "Building kernel..."
	cd kernel/system && $(MAKE) build
	cd kernel && $(MAKE) build

# Phase 4: Servers
servers: libs
	@echo "Building servers..."
	cd servers/pm && $(MAKE) build
	cd servers/fs && $(MAKE) build
	cd servers/rs && $(MAKE) build
	cd servers/init && $(MAKE) build

# Phase 5: Drivers
drivers: libs
	@echo "Building drivers..."
	cd drivers/tty/keymaps && $(MAKE) all
	cd drivers/tty && $(MAKE) build
	cd drivers/memory && $(MAKE) build
	cd drivers/at_wini && $(MAKE) build
	cd drivers/log && $(MAKE) build

# Clean everything
clean:
	cd include && $(MAKE) clean
	cd kernel/system && $(MAKE) clean
	cd kernel && $(MAKE) clean
	cd servers/pm && $(MAKE) clean
	cd servers/fs && $(MAKE) clean
	cd servers/rs && $(MAKE) clean
	cd servers/init && $(MAKE) clean
	cd drivers/libdriver && $(MAKE) clean
	cd drivers/libpci && $(MAKE) clean
	cd drivers/tty/keymaps && $(MAKE) clean
	cd drivers/tty && $(MAKE) clean
	cd drivers/memory && $(MAKE) clean
	cd drivers/at_wini && $(MAKE) clean
	cd drivers/log && $(MAKE) clean
	rm -rf boot/ usr/

# Help
help:
	@echo "Minix 3 Build System"
	@echo ""
	@echo "Usage:"
	@echo "  make          # Incremental build (fast)"
	@echo "  make clean    # Clean all artifacts"
	@echo "  make build    # Full build"
	@echo ""
	@echo "Override compiler:"
	@echo "  CC=gcc make"


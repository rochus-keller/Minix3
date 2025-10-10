#!/bin/bash
# Master build script for Minix 3 with TCC
# Based on Minix 3 book version (www.minix3.org/doc/AppendixB.html)
# Modified for TCC i386 compilation

set -e  # Exit on error

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
MINIX_ROOT=$(pwd)
BUILD_JOBS=${BUILD_JOBS:-1}
INSTALL_SYSTEM=${INSTALL_SYSTEM:-no}  # Set to 'yes' for system-wide install

# Export compiler settings
export CC=tcc
export AS=as
export LD=ld
export AR=ar
export RANLIB=ranlib

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Minix 3 Build System for TCC${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Build root: $MINIX_ROOT"
echo "Compiler: $CC"
echo "Architecture: i386"
echo "System install: $INSTALL_SYSTEM"
echo ""

# Function to print status
print_status() {
    echo -e "${GREEN}==>${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}Warning:${NC} $1"
}

print_error() {
    echo -e "${RED}Error:${NC} $1"
}

# Function to build a component
build_component() {
    local dir=$1
    local name=$2
    
    print_status "Building $name..."
    cd "$MINIX_ROOT/$dir"
    make clean 2>/dev/null || true
    make build
    echo ""
}

# Function to install a component (optional)
install_component() {
    local dir=$1
    local name=$2
    
    if [ "$INSTALL_SYSTEM" = "yes" ]; then
        print_status "Installing $name..."
        cd "$MINIX_ROOT/$dir"
        sudo make install
        echo ""
    fi
}

# Check prerequisites
print_status "Checking prerequisites..."

if ! command -v tcc &> /dev/null; then
    print_error "TCC not found. Please install TCC (Tiny C Compiler)"
    exit 1
fi

if ! command -v as &> /dev/null; then
    print_error "GNU assembler (as) not found. Please install binutils"
    exit 1
fi

if ! command -v ld &> /dev/null; then
    print_error "GNU linker (ld) not found. Please install binutils"
    exit 1
fi

if ! command -v ar &> /dev/null; then
    print_error "GNU archiver (ar) not found. Please install binutils"
    exit 1
fi

print_status "All prerequisites found"
echo ""

# ========================================
# PHASE 1: Headers
# ========================================
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}PHASE 1: Installing Headers${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

cd "$MINIX_ROOT/include"

if [ "$INSTALL_SYSTEM" = "yes" ]; then
    print_status "Installing headers to /usr/include (requires root)..."
    sudo make install
else
    print_status "Installing headers locally to ./usr/include..."
    make install-local
fi

print_status "Headers installed successfully"
echo ""

# ========================================
# PHASE 2: Driver Libraries
# ========================================
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}PHASE 2: Building Driver Libraries${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

build_component "drivers/libdriver" "libdriver (Driver Framework)"
install_component "drivers/libdriver" "libdriver"

build_component "drivers/libpci" "libpci (PCI Bus Support)"
install_component "drivers/libpci" "libpci"

print_status "Driver libraries completed"
echo ""

# ========================================
# PHASE 3: Kernel
# ========================================
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}PHASE 3: Building Kernel${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

build_component "kernel/system" "Kernel System Call Handlers"
build_component "kernel" "Minix Kernel"
install_component "kernel" "Kernel"

print_status "Kernel completed"
echo ""

# ========================================
# PHASE 4: System Servers
# ========================================
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}PHASE 4: Building System Servers${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

build_component "servers/pm" "Process Manager (PM)"
install_component "servers/pm" "PM"

build_component "servers/fs" "File System (FS)"
install_component "servers/fs" "FS"

build_component "servers/rs" "Reincarnation Server (RS)"
install_component "servers/rs" "RS"

build_component "servers/init" "Init Process"
install_component "servers/init" "Init"

print_status "System servers completed"
echo ""

# ========================================
# PHASE 5: Device Drivers
# ========================================
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}PHASE 5: Building Device Drivers${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Build keymaps first
build_component "drivers/tty/keymaps" "Keyboard Maps"
install_component "drivers/tty/keymaps" "Keyboard Maps"

# Build drivers
build_component "drivers/tty" "TTY Driver (Terminal/Console)"
install_component "drivers/tty" "TTY"

build_component "drivers/memory" "Memory Driver"
install_component "drivers/memory" "Memory"

build_component "drivers/at_wini" "AT_WINI Driver (Disk Controller)"
install_component "drivers/at_wini" "AT_WINI"

build_component "drivers/log" "Log Driver (System Logging)"
install_component "drivers/log" "Log"

print_status "Device drivers completed"
echo ""

# ========================================
# Build Summary
# ========================================
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Build Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

cd "$MINIX_ROOT"

print_status "Verifying build outputs..."

# Check kernel
if [ -f "kernel/kernel" ]; then
    echo -e "  ${GREEN}✓${NC} kernel/kernel ($(stat -f%z kernel/kernel 2>/dev/null || stat -c%s kernel/kernel 2>/dev/null) bytes)"
else
    echo -e "  ${RED}✗${NC} kernel/kernel - MISSING"
fi

# Check servers
for server in pm fs rs init; do
    if [ -f "servers/$server/$server" ]; then
        echo -e "  ${GREEN}✓${NC} servers/$server/$server"
    else
        echo -e "  ${RED}✗${NC} servers/$server/$server - MISSING"
    fi
done

# Check RS service utility
if [ -f "servers/rs/service" ]; then
    echo -e "  ${GREEN}✓${NC} servers/rs/service (utility)"
else
    echo -e "  ${RED}✗${NC} servers/rs/service - MISSING"
fi

# Check drivers
for driver in tty memory at_wini log; do
    if [ -f "drivers/$driver/$driver" ]; then
        echo -e "  ${GREEN}✓${NC} drivers/$driver/$driver"
    else
        echo -e "  ${RED}✗${NC} drivers/$driver/$driver - MISSING"
    fi
done

# Check libraries
for lib in libdriver libpci; do
    if [ -f "drivers/$lib/$lib.a" ]; then
        echo -e "  ${GREEN}✓${NC} drivers/$lib/$lib.a"
    else
        echo -e "  ${RED}✗${NC} drivers/$lib/$lib.a - MISSING"
    fi
done

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Build completed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

echo "Build artifacts:"
echo "  - Kernel:      kernel/kernel"
echo "  - Servers:     servers/{pm,fs,rs,init}/"
echo "  - Drivers:     drivers/{tty,memory,at_wini,log}/"
echo "  - Libraries:   drivers/{libdriver,libpci}/"
echo ""

if [ "$INSTALL_SYSTEM" != "yes" ]; then
    print_warning "System installation was not performed."
    echo "To install system-wide, run:"
    echo "  INSTALL_SYSTEM=yes ./build.sh"
fi

echo ""
echo "Next steps:"
echo "  1. Review the build outputs above"
echo "  2. Create a boot image with these components"
echo "  3. Test the system in an emulator (QEMU, Bochs, etc.)"
echo ""


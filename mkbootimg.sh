#!/bin/bash
# Create Minix 3 boot image for testing
# Combines kernel, servers, and drivers into a bootable image

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

MINIX_ROOT=$(pwd)
BOOT_DIR="boot"
IMAGE_NAME="minix_boot.img"
IMAGE_SIZE_MB=10

print_status() {
    echo -e "${GREEN}==>${NC} $1"
}

print_error() {
    echo -e "${RED}Error:${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}Warning:${NC} $1"
}

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Minix 3 Boot Image Creator${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if build was successful
print_status "Verifying build outputs..."

REQUIRED_FILES=(
    "kernel/kernel"
    "servers/pm/pm"
    "servers/fs/fs"
    "servers/rs/rs"
    "servers/init/init"
    "drivers/tty/tty"
    "drivers/memory/memory"
    "drivers/at_wini/at_wini"
    "drivers/log/log"
)

MISSING_FILES=0
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        print_error "Missing: $file"
        MISSING_FILES=$((MISSING_FILES + 1))
    fi
done

if [ $MISSING_FILES -gt 0 ]; then
    print_error "Build incomplete. Run ./build.sh first."
    exit 1
fi

print_status "All required files found"
echo ""

# Create boot directory structure
print_status "Creating boot directory structure..."
rm -rf "$BOOT_DIR"
mkdir -p "$BOOT_DIR"/{image,minix}

# Copy binaries to boot directory
print_status "Copying kernel and system components..."

cp kernel/kernel "$BOOT_DIR/minix/"
cp servers/pm/pm "$BOOT_DIR/minix/"
cp servers/fs/fs "$BOOT_DIR/minix/"
cp servers/rs/rs "$BOOT_DIR/minix/"
cp servers/init/init "$BOOT_DIR/minix/"
cp servers/rs/service "$BOOT_DIR/minix/" 2>/dev/null || true

print_status "Copying device drivers..."
cp drivers/tty/tty "$BOOT_DIR/minix/"
cp drivers/memory/memory "$BOOT_DIR/minix/"
cp drivers/at_wini/at_wini "$BOOT_DIR/minix/"
cp drivers/log/log "$BOOT_DIR/minix/"

# Create image info file
cat > "$BOOT_DIR/minix/image.txt" << EOF
Minix 3 Boot Image
==================
Build date: $(date)
Compiler: TCC (Tiny C Compiler)
Architecture: i386

Components:
-----------
Kernel: kernel
Servers: pm, fs, rs, init
Drivers: tty, memory, at_wini, log

Boot order:
-----------
1. kernel (loads at 1MB)
2. memory (provides /dev/mem, /dev/null, /dev/ram)
3. log (system logging)
4. tty (console/keyboard)
5. at_wini (disk access)
6. fs (filesystem server)
7. pm (process manager)
8. init (system initialization)
9. rs (reincarnation server - monitors all services)
EOF

print_status "Boot image directory created"
echo ""

# Display component sizes
echo -e "${BLUE}Component Sizes:${NC}"
echo "----------------"
ls -lh "$BOOT_DIR/minix/" | awk 'NR>1 {printf "  %-15s %8s\n", $9, $5}'
echo ""

# Calculate total size
TOTAL_SIZE=$(du -sh "$BOOT_DIR/minix" | awk '{print $1}')
echo -e "Total size: ${GREEN}$TOTAL_SIZE${NC}"
echo ""

print_status "Boot directory ready at: $BOOT_DIR/"
echo ""

# Create a simple manifest
print_status "Creating boot manifest..."
cat > "$BOOT_DIR/MANIFEST" << EOF
# Minix 3 Boot Manifest
# This file lists the boot order and component dependencies

# Phase 1: Kernel
kernel

# Phase 2: Critical Drivers (needed before FS)
memory
log

# Phase 3: Console (for user interaction)
tty

# Phase 4: Storage (needed for FS)
at_wini

# Phase 5: System Servers
fs
pm

# Phase 6: System Services
init
rs
EOF

print_status "Boot manifest created"
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Boot Image Created Successfully${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Boot directory: $BOOT_DIR/"
echo "Components: $(ls "$BOOT_DIR/minix/" | wc -l) files"
echo "Total size: $TOTAL_SIZE"
echo ""
echo "Next steps:"
echo "  1. Test with: ./run-qemu.sh"
echo "  2. Or manually create bootable disk image"
echo ""


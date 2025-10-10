#!/bin/bash
# Run Minix 3 in QEMU with virtual disk

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DISK_IMAGE="minix3.img"
DISK_SIZE="512M"
BOOT_DIR="boot"

print_status() {
    echo -e "${GREEN}==>${NC} $1"
}

print_error() {
    echo -e "${RED}Error:${NC} $1"
}

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Minix 3 QEMU with Virtual Disk${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check prerequisites
if ! command -v qemu-system-i386 &> /dev/null; then
    print_error "qemu-system-i386 not found."
    exit 1
fi

if ! command -v qemu-img &> /dev/null; then
    print_error "qemu-img not found."
    exit 1
fi

# Create virtual disk if it doesn't exist
if [ ! -f "$DISK_IMAGE" ]; then
    print_status "Creating virtual disk ($DISK_SIZE)..."
    qemu-img create -f qcow2 "$DISK_IMAGE" "$DISK_SIZE"
    echo ""
fi

# Check if boot image exists
if [ ! -d "$BOOT_DIR/minix" ]; then
    print_error "Boot directory not found. Run ./mkbootimg.sh first."
    exit 1
fi

print_status "Starting QEMU with virtual disk..."
echo ""
echo "Configuration:"
echo "  Memory: 256M"
echo "  CPUs: 1"
echo "  Disk: $DISK_IMAGE ($DISK_SIZE)"
echo "  Kernel: $BOOT_DIR/minix/kernel"
echo ""

# QEMU with disk
qemu-system-i386 \
    -machine pc \
    -cpu pentium3 \
    -m 256M \
    -smp 1 \
    -drive file="$DISK_IMAGE",format=qcow2,if=ide \
    -kernel "$BOOT_DIR/minix/kernel" \
    -serial stdio \
    -boot c \
    -display gtk \
    -no-reboot

echo ""
print_status "QEMU session ended"


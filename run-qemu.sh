#!/bin/bash
# Run Minix 3 in QEMU for testing

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

MINIX_ROOT=$(pwd)
BOOT_DIR="boot"
KERNEL="$BOOT_DIR/minix/kernel"

# QEMU settings
QEMU_MEMORY=128M
QEMU_CPU=1
QEMU_MACHINE=pc
QEMU_DISPLAY="-display gtk"  # Use -nographic for console only

print_status() {
    echo -e "${GREEN}==>${NC} $1"
}

print_error() {
    echo -e "${RED}Error:${NC} $1"
}

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Minix 3 QEMU Test Environment${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check prerequisites
if ! command -v qemu-system-i386 &> /dev/null; then
    print_error "qemu-system-i386 not found. Please install QEMU."
    echo "  Ubuntu/Debian: sudo apt install qemu-system-x86"
    echo "  Fedora: sudo dnf install qemu-system-x86"
    echo "  macOS: brew install qemu"
    exit 1
fi

# Check if boot image exists
if [ ! -f "$KERNEL" ]; then
    print_error "Kernel not found. Run ./mkbootimg.sh first."
    exit 1
fi

print_status "Starting Minix 3 in QEMU..."
echo ""
echo "Configuration:"
echo "  Memory: $QEMU_MEMORY"
echo "  CPUs: $QEMU_CPU"
echo "  Machine: $QEMU_MACHINE"
echo "  Kernel: $KERNEL"
echo ""
echo "Press Ctrl+Alt+G to release mouse"
echo "Press Ctrl+Alt+Q to quit QEMU"
echo ""

# Create a simple multiboot-compatible boot configuration
# Note: This is a simplified example. Real Minix 3 needs a bootloader like GRUB

# For now, we'll use QEMU's -kernel option for direct kernel loading
print_status "Launching QEMU with direct kernel boot..."
echo ""

# QEMU command with direct kernel boot
qemu-system-i386 \
    -machine $QEMU_MACHINE \
    -cpu pentium3 \
    -m $QEMU_MEMORY \
    -smp $QEMU_CPU \
    -kernel "$KERNEL" \
    -serial stdio \
    -boot c \
    $QEMU_DISPLAY \
    -no-reboot \
    -no-shutdown

echo ""
print_status "QEMU session ended"


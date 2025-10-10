#!/bin/bash
# Debug Minix 3 kernel with QEMU + GDB

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

BOOT_DIR="boot"
KERNEL="$BOOT_DIR/minix/kernel"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Minix 3 Debug Session (QEMU + GDB)${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

if [ ! -f "$KERNEL" ]; then
    echo "Kernel not found. Run ./mkbootimg.sh first."
    exit 1
fi

echo "Starting QEMU with GDB stub on port 1234..."
echo ""
echo "In another terminal, run:"
echo "  gdb $KERNEL"
echo "  (gdb) target remote localhost:1234"
echo "  (gdb) break main"
echo "  (gdb) continue"
echo ""
echo -e "${GREEN}Press Enter to start QEMU...${NC}"
read

qemu-system-i386 \
    -machine pc \
    -cpu pentium3 \
    -m 128M \
    -kernel "$KERNEL" \
    -serial stdio \
    -s \
    -S \
    -display gtk


#!/bin/bash
# Clean all build artifacts

set -e

MINIX_ROOT=$(pwd)

RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Cleaning all build artifacts...${NC}"

# Clean each component
for dir in \
    kernel/system \
    kernel \
    servers/pm \
    servers/fs \
    servers/rs \
    servers/init \
    drivers/libdriver \
    drivers/libpci \
    drivers/tty/keymaps \
    drivers/tty \
    drivers/memory \
    drivers/at_wini \
    drivers/log
do
    if [ -d "$dir" ]; then
        echo "Cleaning $dir..."
        cd "$MINIX_ROOT/$dir"
        make clean 2>/dev/null || true
    fi
done

# Clean local headers
if [ -d "usr/include" ]; then
    echo "Removing local headers..."
    rm -rf usr/include
fi

echo -e "${YELLOW}Clean complete${NC}"


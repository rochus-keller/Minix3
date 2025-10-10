#!/bin/bash
# Quick rebuild script - only rebuilds modified components

set -e

export CC=tcc
export AS=as
export LD=ld

GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}Quick rebuild...${NC}"

# Only rebuild what changed
cd include && make install-local 2>/dev/null || true
cd ../kernel/system && make build
cd ../.. && cd kernel && make build
cd ../servers/pm && make build
cd ../fs && make build
cd ../rs && make build
cd ../init && make build
cd ../../drivers/tty && make build
cd ../memory && make build
cd ../at_wini && make build
cd ../log && make build

echo -e "${GREEN}Quick rebuild complete${NC}"


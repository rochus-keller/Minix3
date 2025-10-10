# Minix 3 Testing Guide

## Overview

This guide covers testing the TCC-compiled Minix 3 system in various emulators.

## Prerequisites

### Required Tools
- **QEMU** (qemu-system-i386)
- **Bochs** (optional, for alternative emulation)
- **GDB** (for debugging)

### Installation

**Ubuntu/Debian:**

`sudo apt install qemu-system-x86 bochs gdb`

**Fedora:**

`sudo dnf install qemu-system-x86 bochs gdb`

**macOS:**

`brew install qemu bochs gdb`

## Build Process

### 1. Build Minix 3

`./build.sh`

This creates all kernel, server, and driver binaries.

### 2. Create Boot Image

`./mkbootimg.sh`


This organizes all components into `boot/minix/` directory.

### 3. Test in QEMU

`./run-qemu.sh`

## Testing Scenarios

### Scenario 1: Basic Kernel Boot Test

`./run-qemu.sh`

**Expected output:**
- Kernel boots
- Memory driver initializes
- Console appears
- No immediate crashes

**What to check:**
- Kernel prints boot messages
- Memory detection succeeds
- No panic messages

### Scenario 2: QEMU with Virtual Disk

`./run-qemu-disk.sh`

**Expected output:**
- Kernel boots
- at_wini driver detects disk
- Filesystem attempts to mount

### Scenario 3: Bochs Emulation

`bochs -f bochsrc.txt`

**Expected output:**
- More detailed CPU emulation
- Slower but more accurate
- Better for debugging hardware issues

### Scenario 4: GDB Debugging

Terminal 1

`./debug-qemu.sh`

Terminal 2

`gdb boot/minix/kernel`
```
(gdb) target remote localhost:1234
(gdb) break main
(gdb) continue
```

## Common Issues

### Issue 1: Kernel Doesn't Boot
**Symptoms:** QEMU hangs or crashes immediately

**Solutions:**
1. Verify kernel was built: `ls -l boot/minix/kernel`
2. Check for errors in build: `./build.sh 2>&1 | tee build.log`
3. Ensure TCC generated valid code: `file boot/minix/kernel`

### Issue 2: "No Multiboot Header"
**Symptoms:** QEMU reports missing multiboot header

**Solutions:**
1. The kernel needs multiboot header in assembly
2. Check mpx386.s has proper multiboot magic
3. Use GRUB as bootloader (advanced)

### Issue 3: Triple Fault
**Symptoms:** CPU resets immediately after boot

**Solutions:**
1. Check protected mode initialization
2. Verify GDT/IDT setup in protect.c
3. Enable Bochs triple fault debugging

### Issue 4: No Video Output
**Symptoms:** Black screen but QEMU running

**Solutions:**
1. Try console mode: add `-nographic` to QEMU
2. Check TTY driver initialization
3. Verify video memory access in console.c

## Kernel Command Line Options

QEMU supports passing options to kernel:

`qemu-system-i386 -kernel boot/minix/kernel -append "debug verbose"`

Useful options:
- `debug` - Enable debug output
- `verbose` - Detailed boot messages
- `single` - Single-user mode

## Performance Tuning

### Faster Boot

```
qemu-system-i386 -kernel boot/minix/kernel -m 256M -cpu host -enable-kvm # Linux only
```

### Slower (More Accurate)

`bochs -f bochsrc.txt`

## Serial Console Output

To capture all kernel messages:

`./run-qemu.sh 2>&1 | tee kernel.log`

## Network Testing (Advanced)

Enable network in QEMU:

`qemu-system-i386 -kernel boot/minix/kernel -netdev user,id=net0 -device ne2k_pci,netdev=net0`

## Next Steps

1. **Boot successfully** - Kernel loads and initializes
2. **Driver initialization** - All drivers load without errors
3. **Server startup** - PM, FS, RS start successfully
4. **User interaction** - Console accepts input
5. **System stability** - Runs for extended periods

## Troubleshooting Commands

Verify all binaries exist

`ls -lh boot/minix/`

Check binary types

`file boot/minix/*`

Examine kernel symbols

`nm boot/minix/kernel | grep main`

Dump kernel sections

`objdump -h boot/minix/kernel`

Check for undefined symbols

`nm boot/minix/kernel | grep " U "`

Verify architecture

`readelf -h boot/minix/kernel`

## Success Criteria

✓ Kernel loads without panic  
✓ Memory driver initializes  
✓ Console driver provides output  
✓ Disk driver detects virtual disk  
✓ No triple faults or crashes  
✓ System remains stable for 60+ seconds  

## Resources

- Minix 3 Documentation: www.minix3.org
- QEMU Documentation: qemu.org/docs
- Bochs Documentation: bochs.sourceforge.net
- OS Development Wiki: wiki.osdev.org



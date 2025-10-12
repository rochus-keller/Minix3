# Minix 3 - TCC Port for i386

A complete port of the Minix 3 operating system (book version from [minix3.org/doc/AppendixB.html](https://www.minix3.org/doc/AppendixB.html)) to compile with the Tiny C Compiler (TCC) targeting i386 architecture.

[![License: BSD](https://img.shields.io/badge/License-BSD-blue.svg)](LICENSE)

## About

**Minix 3** is a microkernel-based operating system designed for high reliability and fault tolerance. Originally written by Andrew S. Tanenbaum for educational purposes, it has influenced modern operating systems including Linux.

This project ports the **Minix 3 book version** from the original ACK (Amsterdam Compiler Kit) to **TCC (Tiny C Compiler)**, making it easier to build, study, and modify on modern systems.

### Why This Port?

- **Modern compiler**: TCC is actively maintained and widely available
- **Faster compilation**: TCC compiles significantly faster than GCC
- **Simpler toolchain**: No need for ACK or cross-compilation setup
- **Educational value**: Easier for students to build and experiment with
- **Compatibility**: Works on modern Linux, BSD, and macOS systems

## Planned Features

- Full Minix 3 microkernel with i386 protected mode  
- System servers (PM, FS, RS, Init)  
- Device drivers (TTY, Memory, AT_WINI, Log)  
- TCC-optimized build system  
- QEMU testing environment  
- GDB debugging support  
- Modified source for C99/TCC compatibility  
- Automated build scripts  

## Architecture

Minix 3 follows a **microkernel architecture** with strict separation of components:

```
┌─────────────────────────────────────────┐
│        User Applications                │
├─────────────────────────────────────────┤
│  System Servers (User Mode)             │
│  ┌──────┐ ┌──────┐ ┌────┐ ┌──────┐      │
│  │  PM  │ │  FS  │ │ RS │ │ Init │      │
│  └──────┘ └──────┘ └────┘ └──────┘      │
├─────────────────────────────────────────┤
│  Device Drivers (User Mode)             │
│  ┌─────┐ ┌────────┐ ┌─────────┐         │
│  │ TTY │ │ Memory │ │ AT_WINI │ ...     │
│  └─────┘ └────────┘ └─────────┘         │
├─────────────────────────────────────────┤
│        Microkernel (Ring 0)             │
│  -  Process Scheduling                  │
│  -  IPC (Message Passing)               │
│  -  Interrupt Handling                  │
│  -  Memory Management                   │
└─────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Type | Purpose |
|-----------|------|---------|
| **Kernel** | Microkernel | Process scheduling, IPC, interrupts |
| **PM** | Server | Process management, fork/exec/exit |
| **FS** | Server | File system operations, VFS |
| **RS** | Server | Reincarnation (restart crashed services) |
| **Init** | Server | System initialization (PID 1) |
| **TTY** | Driver | Console, keyboard, terminal I/O |
| **Memory** | Driver | /dev/mem, /dev/null, /dev/zero, RAM disk |
| **AT_WINI** | Driver | IDE/ATA disk and CD-ROM controller |
| **Log** | Driver | System logging (/dev/log) |

## Prerequisites

### Required Software

- **TCC (Tiny C Compiler)** - Primary compiler
- **GNU Binutils** - Assembler (as), linker (ld), archiver (ar)
- **Make** - Build automation
- **QEMU** - x86 emulator for testing (optional but recommended)
- **Bash** - For build scripts

### Installation Commands

**Ubuntu/Debian:**
```
sudo apt update
sudo apt install tcc binutils make qemu-system-x86 gdb
```

**Fedora/RHEL:**
```
sudo dnf install tcc binutils make qemu-system-x86 gdb
```

**Arch Linux:**
```
sudo pacman -S tcc binutils make qemu gdb
```

**macOS (Homebrew):**
```
brew install tcc binutils make qemu gdb
```

### Verify Installation

```
tcc -v          # TCC version
as --version    # GNU assembler
ld --version    # GNU linker
qemu-system-i386 --version
```

## Quick Start

# 1. Clone or extract the Minix 3 source
`cd minix3/`

# 2. Make scripts executable
`chmod +x *.sh`

# 3. Build everything
`./build.sh`

# 4. Create boot image
`./mkbootimg.sh`

# 5. Test in QEMU
`./run-qemu.sh`

If successful, the system will build and boot in QEMU.

## Build System

### Available Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `build.sh` | Complete build from scratch | `./build.sh` |
| `clean.sh` | Remove all build artifacts | `./clean.sh` |
| `mkbootimg.sh` | Create bootable image | `./mkbootimg.sh` |
| `run-qemu.sh` | Test in QEMU | `./run-qemu.sh` |
| `run-qemu-disk.sh` | Test with virtual disk | `./run-qemu-disk.sh` |
| `debug-qemu.sh` | Debug with GDB | `./debug-qemu.sh` |

### Build Process Details

The build system follows this order:

**Phase 1: Headers**

`cd include && make install-local`

Installs modified headers to `./usr/include`

**Phase 2: Libraries**
```
cd drivers/libdriver && make build
cd drivers/libpci && make build
```
Creates `libdriver.a` and `libpci.a`

**Phase 3: Kernel**
```
cd kernel/system && make build  # Builds system.a
cd kernel && make build          # Links final kernel
```
Produces `kernel/kernel` binary

**Phase 4: Servers**
```
cd servers/pm && make build      # Process Manager
cd servers/fs && make build      # File System
cd servers/rs && make build      # Reincarnation Server
cd servers/init && make build    # Init process
```

**Phase 5: Drivers**
```
cd drivers/tty && make build     # Terminal driver
cd drivers/memory && make build  # Memory driver
cd drivers/at_wini && make build # Disk driver
cd drivers/log && make build     # Log driver
```

### Build Options

**System-wide installation (requires root):**
```
INSTALL_SYSTEM=yes ./build.sh
```

**Parallel build (if supported):**
```
BUILD_JOBS=4 ./build.sh
```

**Save build log:**
```
./build.sh 2>&1 | tee build.log
```

## Project Structure

```
minix3/
├── README.md                    # This file
├── LICENSE                      # BSD license
├── TESTING.md                  # Testing documentation
│
├── build.sh                    # Main build script
├── clean.sh                    # Clean script
├── mkbootimg.sh                # Boot image creator
├── run-qemu.sh                 # QEMU launcher
├── run-qemu-disk.sh            # QEMU with disk
├── debug-qemu.sh               # Debug launcher
│
├── boot/                       # Generated boot image
│   └── minix/                  # Kernel + servers + drivers
│
├── include/                    # System headers (modified for TCC)
│   ├── Makefile
│   ├── ansi.h                  # Compiler detection
│   ├── errno.h                 # Error codes
│   ├── limits.h                # System limits
│   ├── unistd.h                # POSIX API
│   ├── string.h                # String functions
│   ├── signal.h                # Signal handling
│   ├── fcntl.h                 # File control
│   ├── minix/                  # Minix-specific headers
│   ├── sys/                    # System headers
│   └── ibm/                    # IBM PC specific
│
├── kernel/                     # Microkernel
│   ├── Makefile
│   ├── main.c                  # Kernel entry point
│   ├── proc.c                  # Process management
│   ├── system.c                # System call interface
│   ├── clock.c                 # Timer management
│   ├── protect.c               # Protected mode setup
│   ├── mpx386.s                # Context switching (assembly)
│   ├── klib386.s               # Kernel library (assembly)
│   └── system/                 # System call handlers
│       ├── Makefile
│       ├── do_fork.c           # Fork system call
│       ├── do_exec.c           # Exec system call
│       └── ...                 # 27 system call handlers
│
├── servers/                    # System servers
│   ├── Makefile
│   ├── pm/                     # Process Manager (13 files)
│   │   ├── Makefile
│   │   ├── main.c
│   │   ├── forkexit.c
│   │   └── ...
│   ├── fs/                     # File System (24 files)
│   │   ├── Makefile
│   │   ├── main.c
│   │   ├── open.c
│   │   └── ...
│   ├── rs/                     # Reincarnation Server (2 files)
│   │   ├── Makefile
│   │   ├── rs.c
│   │   ├── manager.c
│   │   └── service.c           # Service utility
│   └── init/                   # Init (1 file)
│       ├── Makefile
│       └── init.c
│
└── drivers/                    # Device drivers
    ├── Makefile
    ├── libdriver/              # Driver framework
    │   ├── Makefile
    │   ├── driver.c
    │   └── drvlib.c
    ├── libpci/                 # PCI bus support
    │   ├── Makefile
    │   ├── pci.c
    │   └── pci_table.c
    ├── tty/                    # Terminal driver (4 files)
    │   ├── Makefile
    │   ├── tty.c
    │   ├── console.c
    │   ├── keyboard.c
    │   ├── vidcopy.c
    │   └── keymaps/            # Keyboard layouts
    │       ├── Makefile
    │       └── us-std.src
    ├── memory/                 # Memory driver (3 files)
    │   ├── Makefile
    │   ├── memory.c
    │   ├── diag.c
    │   └── kputc.c
    ├── at_wini/                # Disk driver (1 file)
    │   ├── Makefile
    │   └── at_wini.c
    └── log/                    # Log driver (3 files)
        ├── Makefile
        ├── log.c
        ├── diag.c
        └── kputc.c
```

## Testing

See TESTING.md

## Troubleshooting

### Build Failures

**Problem:** Compilation errors

**Solution:**
```
./clean.sh
./build.sh 2>&1 | tee build.log
# Review build.log for specific errors
```

**Problem:** Missing TCC

**Solution:**
```
# Ubuntu/Debian
sudo apt install tcc

# Check installation
tcc -v
```

### Boot Failures

**Problem:** Kernel doesn't boot in QEMU

**Solution:**
1. Verify kernel exists: `ls -l boot/minix/kernel`
2. Check binary type: `file boot/minix/kernel`
3. Ensure it's ELF32: `readelf -h boot/minix/kernel`

**Problem:** "No multiboot header" error

**Solution:**
- The kernel needs a proper multiboot header in `mpx386.s`
- May need GRUB bootloader for full multiboot compliance

**Problem:** Triple fault (CPU reset)

**Solution:**
1. Check protected mode setup in `protect.c`
2. Verify GDT/IDT initialization
3. Enable Bochs debugging: `panic: action=ask` in `bochsrc.txt`

### Runtime Issues

**Problem:** Black screen in QEMU

**Solution:**
- Try console mode: `qemu-system-i386 -kernel ... -nographic`
- Check TTY driver compilation
- Verify video memory access

**Problem:** Drivers don't load

**Solution:**
1. Check boot order in `MANIFEST`
2. Verify driver binaries exist
3. Review kernel messages for errors

## Documentation

- **TESTING.md** - Comprehensive testing documentation
- **Original Minix 3 book** - [minix3.org/doc/](https://www.minix3.org/doc/)
- **TCC documentation** - [bellard.org/tcc/tcc-doc.html](https://bellard.org/tcc/tcc-doc.html)
- **OS Dev Wiki** - [wiki.osdev.org](https://wiki.osdev.org)

## License

This project maintains the original **BSD 3-Clause License** from Minix 3.

The modifications for TCC compatibility are released under the same license.

See `LICENSE` file for details.

## Project Status

- [x] Port all Makefiles to TCC
- [x] Update headers for compatibility
- [x] Create build automation
- [x] QEMU testing setup
- [ ] All components compile with TCC
- [ ] Full boot to console
- [ ] User-mode testing
- [ ] Performance benchmarks
- [ ] Additional driver ports

## Version History

- Initial TCC port
- All 16 Makefiles converted
- Modified headers for C99/TCC
- Build automation scripts
- QEMU testing environment
- Documentation

---




## Minix 3.1.0

This is the original version of Minix 3.1.0 as downloaded from
[Github](https://github.com/Stichting-MINIX-Research-Foundation/minix/archive/refs/tags/v3.1.0.tar.gz)
on 2025-10-10. 

All files in the v3.1.0.tar.gz archive have a modification date/time of 2005-10-18 23:04. This is the
same date as the ["Appendix B" version of Minix 3](https://www.minix3.org/doc/AppendixB.html); the
files in the [AppendixB.tar](https://www.minix3.org/doc/AppendixB.tar) archive have a modification date/time of 
2005-10-18 17:09, though. The present 3.1.0 is a modified superset of the "Appendix B" version;
below is a list of the modified files; as can be seen, the modifications are mostly additions.


Note that this Readme.md is not part of the original code, but was added by Rochus for
documentation purpose.

#### How to compile this version

The book says in section 2.6.2:

"To compile MINIX 3, run make in src/tools/. There are several options, for
installing MINIX 3 in different ways. To see the possibilities run make with no
argument. The simplest method is make image."

The book obviously refers to the presen version, since the "tools" directory is not present in
the "Appendix B" version (see below).

#### List of files of v3.1.0 which existed in "Appendix B", but were modified
```
deletes additions
0       13      drivers/Makefile
2       447     drivers/at_wini/at_wini.c
1       1       drivers/at_wini/at_wini.h
0       17      drivers/libdriver/driver.c
0       13      drivers/memory/memory.c
1       1       drivers/tty/Makefile
0       10      drivers/tty/console.c
0       55      drivers/tty/keymaps/Makefile
0       424     drivers/tty/tty.c
0       14      drivers/tty/tty.h
0       16      include/limits.h
7       25      include/minix/config.h
0       30      include/minix/devio.h
11      27      include/minix/sys_config.h
1       1       include/stdio.h
0       5       include/sys/ioctl.h
0       56      include/sys/sigcontext.h
1       1       kernel/Makefile
4       7       kernel/const.h
5       7       kernel/glo.h
0       50      kernel/i8259.c
2       4       kernel/kernel.h
5       19      kernel/main.c
5       33      kernel/proc.c
0       11      kernel/proc.h
0       40      kernel/protect.c
1       7       kernel/proto.h
0       8       kernel/sconst.h
0       18      kernel/system.c
5       124     kernel/system.h
0       10      kernel/system/do_exec.c
0       2       servers/Makefile
1       2       servers/fs/Makefile
0       11      servers/fs/cache.c
0       22      servers/fs/device.c
0       3       servers/fs/dmap.c
0       5       servers/fs/main.c
0       8       servers/fs/proto.h
0       70      servers/fs/select.c
0       204     servers/pm/alloc.c
1       45      servers/pm/break.c
0       9       servers/pm/const.h
0       16      servers/pm/exec.c
0       31      servers/pm/main.c
0       20      servers/pm/misc.c
0       3       servers/pm/param.h
0       12      servers/pm/proto.h
0       22      servers/pm/signal.c
```

#### List of files and directories of v3.1.0 which were added to "Appendix B"
```
	LICENSE
	Makefile
	boot/
	commands/
	drivers/bios_wini/
	drivers/cmos/
	drivers/dp8390/
	drivers/dpeth/
	drivers/floppy/
	drivers/fxp/
	drivers/lance/
	drivers/printer/
	drivers/random/
	drivers/rtl8139/
	drivers/sb16/
	drivers/tty/keymaps/french.src
	drivers/tty/keymaps/german.src
	drivers/tty/keymaps/italian.src
	drivers/tty/keymaps/japanese.src
	drivers/tty/keymaps/latin-am.src
	drivers/tty/keymaps/olivetti.src
	drivers/tty/keymaps/polish.src
	drivers/tty/keymaps/scandinavn.src
	drivers/tty/keymaps/spanish.src
	drivers/tty/keymaps/uk.src
	drivers/tty/keymaps/us-swap.src
	drivers/tty/pty.c
	drivers/tty/rs232.c
	etc/
	include/alloca.h
	include/arpa/
	include/configfile.h
	include/curses.h
	include/env.h
	include/float.h
	include/grp.h
	include/inttypes.h
	include/lib.h
	include/libgen.h
	include/libutil.h
	include/locale.h
	include/math.h
	include/mathconst.h
	include/minix/cdrom.h
	include/minix/dl_eth.h
	include/minix/fslib.h
	include/minix/jmp_buf.h
	include/minix/minlib.h
	include/minix/paths.h
	include/minix/sound.h
	include/minix/swap.h
	include/net/
	include/netdb.h
	include/netinet/
	include/pwd.h
	include/regex.h
	include/regexp.h
	include/setjmp.h
	include/sgtty.h
	include/stdint.h
	include/strings.h
	include/sys/asynchio.h
	include/sys/file.h
	include/sys/ioc_file.h
	include/sys/ioc_scsi.h
	include/sys/ioc_sound.h
	include/sys/ioc_tape.h
	include/sys/mtio.h
	include/sys/param.h
	include/sys/socket.h
	include/sys/times.h
	include/sys/uio.h
	include/sys/un.h
	include/sys/utsname.h
	include/tar.h
	include/termcap.h
	include/tools.h
	include/utime.h
	kernel/debug.c
	kernel/debug.h
	lib/
	man/
	servers/fs/cache2.c
	servers/inet/
	servers/is/
	servers/sm/
	test/
	tools/
```




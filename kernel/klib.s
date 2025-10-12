#
! Chooses between the 8086 and 386 versions of the low level kernel code.

#include <minix/config.h>
#if _WORD_SIZE == 2
#error "16 bit klib no longer supported"
#else
#include "klib386.s"
#endif

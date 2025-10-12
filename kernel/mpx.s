#
! Chooses between the 8086 and 386 versions of the Minix startup code.

#include <minix/config.h>
#if _WORD_SIZE == 2
#error "16 bit mpx no longer supported"
#else
#include "mpx386.s"
#endif

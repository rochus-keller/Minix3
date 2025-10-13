/* Miscellaneous constants used in assembler code. */

#define W _WORD_SIZE  /* Machine word size */

/* Offsets in struct proc. They MUST match proc.h. */

#define P_STACKBASE 0

#define GSREG P_STACKBASE
#define FSREG (GSREG + 2)  /* 386 introduces FS and GS segments */
#define ESREG (FSREG + 2)
#define DSREG (ESREG + 2)
#define DIREG (DSREG + 2)
#define SIREG (DIREG + W)
#define BPREG (SIREG + W)
#define STREG (BPREG + W)  /* hole for another SP */
#define BXREG (STREG + W)
#define DXREG (BXREG + W)
#define CXREG (DXREG + W)
#define AXREG (CXREG + W)
#define RETADR (AXREG + W)  /* return address for save() call */
#define PCREG (RETADR + W)
#define CSREG (PCREG + W)
#define PSWREG (CSREG + W)
#define SPREG (PSWREG + W)
#define SSREG (SPREG + W)
#define P_STACKTOP (SSREG + W)
#define P_LDT_SEL P_STACKTOP
#define P_LDT (P_LDT_SEL + W)

#define Msize 9  /* size of a message in 32-bit words */


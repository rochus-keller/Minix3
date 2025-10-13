# Translated from ACK (Amsterdam Compiler Kit) format to GAS (GNU Assembler) format
# sections

.text
.section .rodata
.data
.bss

#include <minix/config.h>
#include <minix/const.h>
#include "const.h"
#include "sconst.h"
#include "protect.h"

# This file contains a number of assembly code utility routines needed by the
# kernel. They are:

.globl monitor          # exit Minix and return to the monitor
.globl int86            # let the monitor make an 8086 interrupt call
.globl cp_mess          # copies messages from source to destination
.globl exit             # dummy for library routines
.globl _exit            # dummy for library routines
.globl __exit           # dummy for library routines
.globl __main           # dummy for GCC
.globl phys_insw        # transfer data from (disk controller) port to memory
.globl phys_insb        # likewise byte by byte
.globl phys_outsw       # transfer data from memory to (disk controller) port
.globl phys_outsb       # likewise byte by byte
.globl enable_irq       # enable an irq at the 8259 controller
.globl disable_irq      # disable an irq
.globl phys_copy        # copy data from anywhere to anywhere in memory
.globl phys_memset      # write pattern anywhere in memory
.globl mem_rdw          # copy one word from [segment:offset]
.globl reset            # reset the system
.globl idle_task        # task executed when there is no work
.globl level0           # call a function at level 0
.globl read_tsc         # read the cycle counter (Pentium and up)
.globl read_cpu_flags   # read the cpu flags

# The routines only guarantee to preserve the registers the C compiler
# expects to be preserved (ebx, esi, edi, ebp, esp, segment registers, and
# direction bit in the flags).

.text


#*===========================================================================*
#*                                monitor                                    *
#*===========================================================================*
# PUBLIC void monitor();
# Return to the monitor.

monitor:
    movl (mon_sp), %esp        # restore monitor stack pointer
    movw $SS_SELECTOR, %dx      # monitor data segment
    movw %dx, %ds
    movw %dx, %es
    movw %dx, %fs
    movw %dx, %gs
    movw %dx, %ss
    popl %edi
    popl %esi
    popl %ebp
    lretw                       # return to the monitor

#*===========================================================================*
#*                                int86                                      *
#*===========================================================================*
# PUBLIC void int86();

int86:
    cmpb $0, (mon_return)      # is the monitor there?
    jnz 0f
    movb $0x01, %ah             # an int 13 error seems appropriate
    movb %ah, (reg86+ 0)       # reg86.w.f = 1 (set carry flag)
    movb %ah, (reg86+13)       # reg86.b.ah = 0x01 = "invalid command"
    ret

0:  pushl %ebp                  # save C registers
    pushl %esi
    pushl %edi
    pushl %ebx
    pushf                       # save flags
    cli                         # no interruptions

    inb $INT2_CTLMASK
    movb %al, %ah
    inb $INT_CTLMASK
    pushl %eax                  # save interrupt masks
    movl (irq_use), %eax       # map of in-use IRQ's
    andl $MASK_IRQS1, %eax
    movl %eax, (irq_use)
    movb %ah, %al
    outb $INT2_CTLMASK          # disable all irq's
    movb $MASK_IRQS2, %al
    outb $INT_CTLMASK

    movl $(reg86), %ebx        # power of monitor access reg86
    call *mon_return           # set-up trap and switching by monitor
    sti

    popl %eax
    outb $INT_CTLMASK           # restore interrupt masks
    movb %ah, %al
    outb $INT2_CTLMASK

    popf                        # restore flags
    popl %ebx                   # restore C registers
    popl %edi
    popl %esi
    popl %ebp
    ret

#*===========================================================================*
#*                                cp_mess                                    *
#*===========================================================================*
# PUBLIC void cp_mess(int src, phys_clicks src_clicks, vir_bytes src_offset,
#                     phys_clicks dst_clicks, vir_bytes dst_offset);
# This routine makes a fast copy of a message from anywhere in the address
# space to anywhere else.  It also copies the source address provided as a
# parameter to the call into the first word of the destination message.
#
# Note that the message size, "Msize" is in DWORDS (not bytes) and must be set
# correctly.  Changing the definition of message in the type file and not
# changing it here will lead to total disaster.
#
# This routine is not used in kernels that have MEMCPY_VARIANT defined.
# They call phys_copy instead.

CM_ARGS     =   4 + 4 + 4 + 4 + 4       # 4 + 4 + 4 + 4 + 4
#               es  ds edi esi eip       proc scl sof dcl dof

        .align  16
cp_mess:
    cld
    pushl %esi
    pushl %edi
    pushl %ds
    pushl %es

    movl $FLAT_DS_SELECTOR, %eax
    movw %ax, %ds
    movw %ax, %es

    movl CM_ARGS+4(%esp), %esi
    shll $CLICK_SHIFT, %esi
    addl CM_ARGS+4+4(%esp), %esi        # src_clicks + src_offset
    movl CM_ARGS+4+4+4(%esp), %edi
    shll $CLICK_SHIFT, %edi
    addl CM_ARGS+4+4+4+4(%esp), %edi    # dst_clicks + dst_offset

    movl CM_ARGS(%esp), %eax            # copy process number to message
    stosl
    addl $4, %esi                       # don't copy first word (proc number)
    movl $(Msize-1), %ecx               # remember, first word doesn't count
    rep
    movsl                               # copy the message

    popl %es
    popl %ds
    popl %edi
    popl %esi
    ret

#*===========================================================================*
#*                              exit                                         *
#*===========================================================================*
# PUBLIC void exit();
# Some library routines use exit, so provide a dummy version.
# Actual calls to exit cannot occur in the kernel.
# GNU CC likes to call __main from main() for nonobvious reasons.

exit:
_exit:
__exit:
    sti
    jmp __exit

__main:
    ret

#*===========================================================================*
#*                             phys_insw                                     *
#*===========================================================================*
# PUBLIC void phys_insw(Port_t port, phys_bytes buf, size_t count);
# Input an array from an I/O port.  Absolute address version of insw().

phys_insw:
    pushl %ebp
    movl %esp, %ebp
    cld
    pushl %edi
    pushl %es
    movl $FLAT_DS_SELECTOR, %ecx
    movw %cx, %es
    movl 8(%ebp), %edx              # port to read from
    movl 12(%ebp), %edi             # destination addr
    movl 16(%ebp), %ecx             # byte count
    shrl $1, %ecx                   # word count
    rep insw                        # input many words
    popl %es
    popl %edi
    popl %ebp
    ret

#*===========================================================================*
#*                             phys_insb                                     *
#*===========================================================================*
# PUBLIC void phys_insb(Port_t port, phys_bytes buf, size_t count);
# Input an array from an I/O port.  Absolute address version of insb().

phys_insb:
    pushl %ebp
    movl %esp, %ebp
    cld
    pushl %edi
    pushl %es
    movl $FLAT_DS_SELECTOR, %ecx
    movw %cx, %es
    movl 8(%ebp), %edx              # port to read from
    movl 12(%ebp), %edi             # destination addr
    movl 16(%ebp), %ecx             # byte count
    rep insb                        # input many bytes
    popl %es
    popl %edi
    popl %ebp
    ret

#*===========================================================================*
#*                             phys_outsw                                    *
#*===========================================================================*
# PUBLIC void phys_outsw(Port_t port, phys_bytes buf, size_t count);
# Output an array to an I/O port.  Absolute address version of outsw().

        .align  16
phys_outsw:
    pushl %ebp
    movl %esp, %ebp
    cld
    pushl %esi
    pushl %ds
    movl $FLAT_DS_SELECTOR, %ecx
    movw %cx, %ds
    movl 8(%ebp), %edx              # port to write to
    movl 12(%ebp), %esi             # source addr
    movl 16(%ebp), %ecx             # byte count
    shrl $1, %ecx                   # word count
    rep outsw                       # output many words
    popl %ds
    popl %esi
    popl %ebp
    ret

#*===========================================================================*
#*                             phys_outsb                                    *
#*===========================================================================*
# PUBLIC void phys_outsb(Port_t port, phys_bytes buf, size_t count);
# Output an array to an I/O port.  Absolute address version of outsb().

phys_outsb:
    pushl %ebp
    movl %esp, %ebp
    cld
    pushl %esi
    pushl %ds
    movl $FLAT_DS_SELECTOR, %ecx
    movw %cx, %ds
    movl 8(%ebp), %edx              # port to write to
    movl 12(%ebp), %esi             # source addr
    movl 16(%ebp), %ecx             # byte count
    rep outsb                       # output many bytes
    popl %ds
    popl %esi
    popl %ebp
    ret

#*===========================================================================*
#*                           enable_irq                                      *
#*===========================================================================*
# PUBLIC void enable_irq(irq_hook_t *hook)
# Enable an interrupt request line by clearing an 8259 bit.
# Equivalent C code for irq < 8:
/*   if ((irq_actids[hook->irq] &= ~hook->id) == 0)
       outb(INT_CTLMASK, inb(INT_CTLMASK) & ~(1 << irq)); */

        .align  16
enable_irq:
    pushl %ebp
    movl %esp, %ebp
    pushf
    cli
    movl 8(%ebp), %eax              # hook
    movl 8(%eax), %ecx              # irq
    movl 12(%eax), %eax             # id bit
    notl %eax
    andl %eax, irq_actids(,%ecx,4) # clear this id bit
    jnz en_done                     # still masked by other handlers?
    movb $~1, %ah
    rolb %cl, %ah                   # ah = ~(1 << (irq % 8))
    movl $INT_CTLMASK, %edx         # enable irq < 8 at the master 8259
    cmpb $8, %cl
    jb 0f
    movl $INT2_CTLMASK, %edx        # enable irq >= 8 at the slave 8259
0:  inb %dx
    andb %ah, %al
    outb %dx                        # clear bit at the 8259
en_done:
    popf
    leave
    ret

#*==========================================================================*
#*                           disable_irq                                    *
#*==========================================================================*/
# PUBLIC int disable_irq(irq_hook_t *hook)
# Disable an interrupt request line by setting an 8259 bit.
# Equivalent C code for irq < 8:
#   irq_actids[hook->irq] |= hook->id;
#   outb(INT_CTLMASK, inb(INT_CTLMASK) | (1 << irq));
# Returns true iff the interrupt was not already disabled.

        .align  16
disable_irq:
    pushl %ebp
    movl %esp, %ebp
    pushf
    cli
    movl 8(%ebp), %eax              # hook
    movl 8(%eax), %ecx              # irq
    movl 12(%eax), %eax             # id bit
    orl %eax, irq_actids(,%ecx,4)  # set this id bit
    movb $1, %ah
    rolb %cl, %ah                   # ah = (1 << (irq % 8))
    movl $INT_CTLMASK, %edx         # disable irq < 8 at the master 8259
    cmpb $8, %cl
    jb 0f
    movl $INT2_CTLMASK, %edx        # disable irq >= 8 at the slave 8259
0:  inb %dx
    testb %ah, %al
    jnz dis_already                 # already disabled?
    orb %ah, %al
    outb %dx                        # set bit at the 8259
    movl $1, %eax                   # disabled by this function
    popf
    leave
    ret

dis_already:
    xorl %eax, %eax                 # already disabled
    popf
    leave
    ret

#*===========================================================================*
#*                           phys_copy                                       *
#*===========================================================================*
# PUBLIC void phys_copy(phys_bytes source, phys_bytes destination,
#                       phys_bytes bytecount);
# Copy a block of physical memory.

PC_ARGS =   4 + 4 + 4 + 4           # 4 + 4 + 4
#           es edi esi eip           src dst len

        .align  16
phys_copy:
    cld
    pushl %esi
    pushl %edi
    pushl %es

    movl $FLAT_DS_SELECTOR, %eax
    movw %ax, %es
    movl PC_ARGS(%esp), %esi
    movl PC_ARGS+4(%esp), %edi
    movl PC_ARGS+4+4(%esp), %eax

    cmpl $10, %eax                  # avoid align overhead for small counts
    jb pc_small
    movl %esi, %ecx                 # align source, hope target is too
    negl %ecx
    andl $3, %ecx                   # count for alignment
    subl %ecx, %eax
    rep
    es movsb

    movl %eax, %ecx
    shrl $2, %ecx                   # count of dwords
    rep
    es movsl
    andl $3, %eax

pc_small:
    xchgl %ecx, %eax                # remainder
    rep
    es movsb

    popl %es
    popl %edi
    popl %esi
    ret

#*===========================================================================*
#*                           phys_memset                                     *
#*===========================================================================*
# PUBLIC void phys_memset(phys_bytes source, unsigned long pattern,
#                         phys_bytes bytecount);
# Fill a block of physical memory with pattern.

        .align  16
phys_memset:
    pushl %ebp
    movl %esp, %ebp
    pushl %esi
    pushl %ebx
    pushl %ds

    movl 8(%ebp), %esi
    movl 16(%ebp), %eax
    movl $FLAT_DS_SELECTOR, %ebx
    movw %bx, %ds
    movl 12(%ebp), %ebx
    shrl $2, %eax

fill_start:
    movl %ebx, (%esi)
    addl $4, %esi
    decl %eax
    jnz fill_start

    # Any remaining bytes?
    movl 16(%ebp), %eax
    andl $3, %eax

remain_fill:
    cmpl $0, %eax
    jz fill_done
    movb 12(%ebp), %bl
    movb %bl, (%esi)
    addl $1, %esi
    incl %ebp
    decl %eax
    jmp remain_fill

fill_done:
    popl %ds
    popl %ebx
    popl %esi
    popl %ebp
    ret

#*===========================================================================*
#*                              mem_rdw                                      *
#*===========================================================================*
# PUBLIC u16_t mem_rdw(U16_t segment, u16_t *offset);
# Load and return word at far pointer segment:offset.

        .align  16
mem_rdw:
    movw %ds, %cx
    movw 4(%esp), %ds               # segment
    movl 4+4(%esp), %eax            # offset
    movzwl (%eax), %eax             # word to return
    movw %cx, %ds
    ret

#*===========================================================================*
#*                              reset                                        *
#*===========================================================================*
# PUBLIC void reset();
# Reset the system by loading IDT with offset 0 and interrupting.

reset:
    lidt (idt_zero)
    int $3                          # anything goes, the 386 will not like it

.data
idt_zero: .long 0, 0

.text

#*===========================================================================*
#*                           idle_task                                       *
#*===========================================================================*

idle_task:
    # This task is called when the system has nothing else to do. The HLT
    # instruction puts the processor in a state where it draws minimum power.
    pushl $halt
    call level0                    # level0(halt)
    popl %eax
    jmp idle_task

halt:
    sti
    hlt
    cli
    ret

#*===========================================================================*
#*                              level0                                       *
#*===========================================================================*
# PUBLIC void level0(void (*func)(void))
# Call a function at permission level 0. This allows kernel tasks to do
# things that are only possible at the most privileged CPU level.

level0:
    movl 4(%esp), %eax
    movl %eax, (_level0_func)
    int $LEVEL0_VECTOR
    ret

#*===========================================================================*
#*                           read_tsc                                        *
#*===========================================================================*
# PUBLIC void read_tsc(unsigned long *high, unsigned long *low);
# Read the cycle counter of the CPU. Pentium and up.

        .align  16
read_tsc:
    .byte 0x0f                      # this is the RDTSC instruction
    .byte 0x31                      # it places the TSC in EDX:EAX
    pushl %ebp
    movl 8(%esp), %ebp
    movl %edx, (%ebp)
    movl 12(%esp), %ebp
    movl %eax, (%ebp)
    popl %ebp
    ret

#*===========================================================================*
#*                           read_cpu_flags                                  *
#*===========================================================================*
# PUBLIC unsigned long read_cpu_flags(void);
# Read CPU status flags from C.

        .align  16
read_cpu_flags:
    pushf
    movl (%esp), %eax
    popf
    ret

/*
Directive Changes: ACK's .sect .text, .sect .data, .sect .bss directives were converted to GAS's .text, .data, and .bss sections.
  Symbol definitions using .define became .globl declarations.
Operand Order: ACK uses Intel-style destination-first syntax (mov dst, src), while GAS uses AT&T source-first syntax
  (movl src, dst). All instructions were reversed accordingly.
Register and Immediate Notation: Registers now require the % prefix (%eax instead of eax), and immediate
  values require the $ prefix ($0x01 instead of 0x01).
Size Suffixes: GAS requires explicit size suffixes on instructions. Generic mov instructions became movl (long/32-bit),
  movw (word/16-bit), or movb (byte/8-bit) based on operand context.
Instruction-Specific Changes:
Memory Addressing: ACK's memory syntax (eax) became GAS's (%eax), and complex addressing modes like irq_actids(ecx*4) were converted to irq_actids(,%ecx,4).
Segment Overrides: ACK's eseg movsb prefix became GAS's es movsb syntax.
String Operations: Instructions like movs were expanded to size-specific forms (movsl for 32-bit, movsb for 8-bit).
Special Instructions: The o16 prefix (operand size override) combined with retf was translated to lretw (far return with 16-bit operand).
  The inb and outb instructions maintain the same mnemonic but with reversed operands.
Comments and Labels: Comments changed from ! to #. ACK's numeric label syntax (0:, 0f, 0b) was preserved as
  GAS supports the same forward/backward reference mechanism.
Data Declarations: ACK's .data4 directive for 32-bit values became .long in GAS.
​*/

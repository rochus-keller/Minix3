# This file, mpx386.s, is included by mpx.s when Minix is compiled for
# 32-bit Intel CPUs. The alternative mpx88.s is compiled for 16-bit CPUs.
# This file is part of the lowest layer of the MINIX kernel. (The other part
# is "proc.c".) The lowest layer does process switching and message handling.
# Furthermore it contains the assembler startup code for Minix and the 32-bit
# interrupt handlers. It cooperates with the code in "start.c" to set up a
# good environment for main().
# Every transition to the kernel goes through this file. Transitions to the
# kernel may be nested. The initial entry may be with a system call (i.e.,
# send or receive a message), an exception or a hardware interrupt; kernel
# reentries may only be made by hardware interrupts. The count of reentries
# is kept in "k_reenter". It is important for deciding whether to switch to
# the kernel stack and for protecting the message passing code in "proc.c".
# For the message passing trap, most of the machine state is saved in the
# proc table. (Some of the registers need not be saved.) Then the stack is
# switched to "k_stack", and interrupts are reenabled. Finally, the system
# call handler (in C) is called. When it returns, interrupts are disabled
# again and the code falls into the restart routine, to finish off held-up
# interrupts and run the process or task whose pointer is in "proc_ptr".
# Hardware interrupt handlers do the same, except (1) The entire state must
# be saved. (2) There are too many handlers to do this inline, so the save
# routine is called. A few cycles are saved by pushing the address of the
# appropiate restart routine for a return later. (3) A stack switch is
# avoided when the stack is already switched. (4) The (master) 8259 interrupt
# controller is reenabled centrally in save(). (5) Each interrupt handler
# masks its interrupt line using the 8259 before enabling (other unmasked)
# interrupts, and unmasks it after servicing the interrupt. This limits the
# nest level to the number of lines and protects the handler from itself.
# For communication with the boot monitor at startup time some constant
# data are compiled into the beginning of the text segment. This facilitates
# reading the data at the start of the boot process, since only the first
# sector of the file needs to be read.
# Some data storage is also allocated at the end of this file. This data
# will be at the start of the data segment of the kernel and will be read
# and modified by the boot monitor before the kernel starts.

# sections
.text
begtext:
.section .rom
begrom:
.data
begdata:
.bss
begbss:

#include <minix/config.h>
#include <minix/const.h>
#include <minix/com.h>
#include <ibm/interrupt.h>
#include "const.h"
#include "protect.h"
#include "sconst.h"

/* Selected 386 tss offsets. */
#define TSS3_S_SP0 4

# Exported functions
# Note: in assembly language the .globl statement applied to a function name
# is loosely equivalent to a prototype in C code -- it makes it possible to
# link to an entity declared in the assembly code but does not create
# the entity.

.globl restart
.globl save
.globl divide_error
.globl single_step_exception
.globl nmi
.globl breakpoint_exception
.globl overflow
.globl bounds_check
.globl inval_opcode
.globl copr_not_available
.globl double_fault
.globl copr_seg_overrun
.globl inval_tss
.globl segment_not_present
.globl stack_exception
.globl general_protection
.globl page_fault
.globl copr_error
.globl hwint00		# handlers for hardware interrupts
.globl hwint01
.globl hwint02
.globl hwint03
.globl hwint04
.globl hwint05
.globl hwint06
.globl hwint07
.globl hwint08
.globl hwint09
.globl hwint10
.globl hwint11
.globl hwint12
.globl hwint13
.globl hwint14
.globl hwint15
.globl s_call
.globl p_s_call
.globl level0_call

# Exported variables.
.globl begbss
.globl begdata

.text
#*===========================================================================*
#* MINIX *
#*===========================================================================*
MINIX:				# this is the entry point for the MINIX kernel
	jmp	over_flags		# skip over the next few bytes
	.word	CLICK_SHIFT		# for the monitor: memory granularity
flags:
	.word	0x01FD			# boot monitor flags:
					# call in 386 mode, make bss, make stack,
					# load high, don't patch, will return,
					# uses generic INT, memory vector,
					# new boot code return
	nop				# extra byte to sync up disassembler
over_flags:

# Set up a C stack frame on the monitor stack. (The monitor sets cs and ds
# right. The ss descriptor still references the monitor data segment.)
	movzwl	%sp, %esp		# monitor stack is a 16 bit stack
	push	%ebp
	mov	%esp, %ebp
	push	%esi
	push	%edi
	cmpl	$0, 4(%ebp)		# monitor return vector is
	jz	noret			# nonzero if return possible
	incl	(mon_return)
noret:	movl	%esp, (mon_sp)		# save stack pointer for later return

# Copy the monitor global descriptor table to the address space of kernel and
# switch over to it. Prot_init() can then update it with immediate effect.

	sgdt	(_gdt+GDT_SELECTOR)	# get the monitor gdtr
	movl	(_gdt+GDT_SELECTOR+2), %esi	# absolute address of GDT
	movl	$_gdt, %ebx		# address of kernel GDT
	movl	$8*8, %ecx		# copying eight descriptors
copygdt:
	movb	%es:(%esi), %al
	movb	%al, (%ebx)
	inc	%esi
	inc	%ebx
	loop	copygdt
	movl	(_gdt+DS_SELECTOR+2), %eax	# base of kernel data
	andl	$0x00FFFFFF, %eax	# only 24 bits
	addl	$_gdt, %eax		# eax = vir2phys(gdt)
	movl	%eax, (_gdt+GDT_SELECTOR+2)	# set base of GDT
	lgdt	(_gdt+GDT_SELECTOR)	# switch over to kernel GDT

# Locate boot parameters, set up kernel segment registers and stack.
	movl	8(%ebp), %ebx		# boot parameters offset
	movl	12(%ebp), %edx		# boot parameters length
	movl	16(%ebp), %eax		# address of a.out headers
	movl	%eax, (aout)
	mov	%ds, %ax		# kernel data
	mov	%ax, %es
	mov	%ax, %fs
	mov	%ax, %gs
	mov	%ax, %ss
	movl	$k_stktop, %esp		# set sp to point to the top of kernel stack

# Call C startup code to set up a proper environment to run main().
	push	%edx
	push	%ebx
	push	$SS_SELECTOR
	push	$DS_SELECTOR
	push	$CS_SELECTOR
	call	cstart			# cstart(cs, ds, mds, parmoff, parmlen)
	add	$5*4, %esp

# Reload gdtr, idtr and the segment registers to global descriptor table set
# up by prot_init().

	lgdt	(_gdt+GDT_SELECTOR)
	lidt	(_gdt+IDT_SELECTOR)
	ljmp	$CS_SELECTOR, $csinit
csinit:
	mov	$DS_SELECTOR, %ax
	mov	%ax, %ds
	mov	%ax, %es
	mov	%ax, %fs
	mov	%ax, %gs
	mov	%ax, %ss
	mov	$TSS_SELECTOR, %ax	# no other TSS is used
	ltr	%ax
	push	$0			# set flags to known good state
	popf				# esp, clear nested task and int enable

	jmp	_main			# main()


#*===========================================================================*
#* interrupt handlers *
#* interrupt handlers for 386 32-bit protected mode *
#*===========================================================================*

#*===========================================================================*
#* hwint00 - 07 *
#*===========================================================================*
# Note this is a macro, it just looks like a subroutine.
.macro hwint_master irq
	call	save		/* save interrupted process state */
	push	(irq_handlers+4*\irq)	/* irq_handlers[irq] */
	call	intr_handle	/* intr_handle(irq_handlers[irq]) */
	pop	%ecx
	cmpl	$0, (irq_actids+4*\irq)	/* interrupt still active? */
	jz	0f
	inb	$INT_CTLMASK	/* get current mask */
	orb	$(1<<\irq), %al	/* mask irq */
	outb	%al, $INT_CTLMASK	/* disable the irq */
0:	movb	$END_OF_INT, %al
	outb	%al, $INT_CTL	/* reenable master 8259 */
	ret			/* restart (another) process */
.endm

# Each of these entry points is an expansion of the hwint_master macro
	.align	16
hwint00:		# Interrupt routine for irq 0 (the clock).
	hwint_master 0

	.align	16
hwint01:		# Interrupt routine for irq 1 (keyboard)
	hwint_master 1

	.align	16
hwint02:		# Interrupt routine for irq 2 (cascade!)
	hwint_master 2

	.align	16
hwint03:		# Interrupt routine for irq 3 (second serial)
	hwint_master 3

	.align	16
hwint04:		# Interrupt routine for irq 4 (first serial)
	hwint_master 4

	.align	16
hwint05:		# Interrupt routine for irq 5 (XT winchester)
	hwint_master 5

	.align	16
hwint06:		# Interrupt routine for irq 6 (floppy)
	hwint_master 6

	.align	16
hwint07:		# Interrupt routine for irq 7 (printer)
	hwint_master 7

#*===========================================================================*
#* hwint08 - 15 *
#*===========================================================================*
# Note this is a macro, it just looks like a subroutine.
.macro hwint_slave irq
	call	save		/* save interrupted process state */
	push	(irq_handlers+4*\irq)	/* irq_handlers[irq] */
	call	intr_handle	/* intr_handle(irq_handlers[irq]) */
	pop	%ecx
	cmpl	$0, (irq_actids+4*\irq)	/* interrupt still active? */
	jz	0f
	inb	$INT2_CTLMASK
	orb	$(1<<(\irq-8)), %al
	outb	%al, $INT2_CTLMASK	/* disable the irq */
0:	movb	$END_OF_INT, %al
	outb	%al, $INT_CTL	/* reenable master 8259 */
	outb	%al, $INT2_CTL	/* reenable slave 8259 */
	ret			/* restart (another) process */
.endm

# Each of these entry points is an expansion of the hwint_slave macro
	.align	16
hwint08:		# Interrupt routine for irq 8 (realtime clock)
	hwint_slave 8

	.align	16
hwint09:		# Interrupt routine for irq 9 (irq 2 redirected)
	hwint_slave 9

	.align	16
hwint10:		# Interrupt routine for irq 10
	hwint_slave 10

	.align	16
hwint11:		# Interrupt routine for irq 11
	hwint_slave 11

	.align	16
hwint12:		# Interrupt routine for irq 12
	hwint_slave 12

	.align	16
hwint13:		# Interrupt routine for irq 13 (FPU exception)
	hwint_slave 13

	.align	16
hwint14:		# Interrupt routine for irq 14 (AT winchester)
	hwint_slave 14

	.align	16
hwint15:		# Interrupt routine for irq 15
	hwint_slave 15

#*===========================================================================*
#* save *
#*===========================================================================*
# Save for protected mode.
# This is much simpler than for 8086 mode, because the stack already points
# into the process table, or has already been switched to the kernel stack.

	.align	16
save:
	cld				# set direction flag to a known value
	pushal				# save "general" registers
	push	%ds			# save ds
	push	%es			# save es
	push	%fs			# save fs
	push	%gs			# save gs
	mov	%ss, %dx		# ss is kernel data segment
	mov	%dx, %ds		# load rest of kernel segments
	mov	%dx, %es		# kernel does not use fs, gs
	movl	%esp, %eax		# prepare to return
	incl	(k_reenter)		# from -1 if not reentering
	jnz	set_restart1		# stack is already kernel stack
	movl	$k_stktop, %esp
	push	$restart		# build return address for int handler
	xorl	%ebp, %ebp		# for stacktrace
	jmp	*RETADR-P_STACKBASE(%eax)
set_restart1:
	push	$restart
	jmp	*RETADR-P_STACKBASE(%eax)

#*===========================================================================*
#* s_call *
#*===========================================================================*
	.align	16
s_call:
p_s_call:
	cld				# set direction flag to a known value
	sub	$6*4, %esp		# skip RETADR, eax, ecx, edx, ebx, est
	push	%ebp			# stack already points into proc table
	push	%esi
	push	%edi
	push	%ds
	push	%es
	push	%fs
	push	%gs
	mov	%ss, %dx
	mov	%dx, %ds
	mov	%dx, %es
	incl	(k_reenter)
	movl	%esp, %esi		# assumes P_STACKBASE == 0
	movl	$k_stktop, %esp
	xorl	%ebp, %ebp		# for stacktrace
					# end of inline save
					# now set up parameters for sys_call()
	push	%ebx			# pointer to user message
	push	%eax			# src/dest
	push	%ecx			# SEND/RECEIVE/BOTH
	call	sys_call		# sys_call(function, src_dest, m_ptr)
					# caller is now explicitly in proc_ptr
	movl	(proc_ptr), %ebx	# return directly to caller
	addl	$3*4, %esp		# clean up parameters
	movl	%eax, AXREG(%ebx)	# sys_call MUST PRESERVE si, di, bp

#*===========================================================================*
#* restart *
#*===========================================================================*
restart:

# Restart the current process or the next process if it is set.

	cmpl	$0, (next_ptr)		# see if another process is scheduled
	jz	0f
	movl	(next_ptr), %eax
	movl	%eax, (proc_ptr)
	movl	$0, (next_ptr)
0:
	cmpl	$0, (sched_ticks)	# check if quantum is up
	jle	switch_ticks		# or interrupts were masked
check_sigs:
	movl	(proc_ptr), %esp	# will assume P_STACKBASE == 0
	lldt	P_LDT_SEL(%esp)		# enable process' segment descriptors
	movl	$TSS3_S_SP0+tss, %eax	# set kernel stack pointer in tss
	movl	%esp, (%eax)
	decl	(k_reenter)
	pop	%gs
	pop	%fs
	pop	%es
	pop	%ds
	popal
	addl	$4, %esp		# skip return address
	iret				# continue process

switch_ticks:
	movl	(bill_ptr), %eax	# pay the current process
	incl	COUNTER(%eax)		# for the tick it last ran
	movl	$1, (sched_ticks)	# reset quantum
	cmpl	(proc_ptr), %eax	# is it the current process?
	jne	check_sigs		# if not, don't reschedule
	call	sched			# if it is, reschedule
	jmp	check_sigs

#*===========================================================================*
#* exception handlers *
#*===========================================================================*
divide_error:
	push	$DIVIDE_VECTOR
	jmp	exception

single_step_exception:
	push	$DEBUG_VECTOR
	jmp	exception

nmi:
	push	$NMI_VECTOR
	jmp	exception

breakpoint_exception:
	push	$BREAKPOINT_VECTOR
	jmp	exception

overflow:
	push	$OVERFLOW_VECTOR
	jmp	exception

bounds_check:
	push	$BOUNDS_VECTOR
	jmp	exception

inval_opcode:
	push	$INVAL_OP_VECTOR
	jmp	exception

copr_not_available:
	push	$COPROC_NOT_VECTOR
	jmp	exception

double_fault:
	push	$DOUBLE_FAULT_VECTOR
	jmp	errexception

copr_seg_overrun:
	push	$COPROC_SEG_VECTOR
	jmp	exception

inval_tss:
	push	$INVAL_TSS_VECTOR
	jmp	errexception

segment_not_present:
	push	$SEG_NOT_VECTOR
	jmp	errexception

stack_exception:
	push	$STACK_FAULT_VECTOR
	jmp	errexception

general_protection:
	push	$PROTECTION_VECTOR
	jmp	errexception

page_fault:
	push	$PAGE_FAULT_VECTOR
	jmp	errexception

copr_error:
	push	$COPROC_ERR_VECTOR
	jmp	exception

#*===========================================================================*
#* exception *
#*===========================================================================*
# This is called for all exceptions which do not push an error code.

	.align	16
exception:
	#TODO sseg
	push	$0			# push fake error code
	#TODO sseg
	push	%eax			# eax is scratch register
	movl	4(%esp), %eax		# old eip
	#TODO sseg
	movl	%eax, 8(%esp)
	movl	(%esp), %eax
	#TODO sseg
	movl	%eax, 4(%esp)
	popl	%eax
	call	save
	push	%eax			# push exception vector
	call	exception		# exception(vec_nr)
	addl	$4, %esp
	cli
	ret

#*===========================================================================*
#* errexception *
#*===========================================================================*
# This is called for all exceptions which do push an error code.

	.align	16
errexception:
	#TODO sseg
	push	%eax			# eax is scratch register
	movl	4(%esp), %eax		# old eip
	#TODO sseg
	movl	%eax, 12(%esp)
	movl	8(%esp), %eax		# old cs
	#TODO sseg
	movl	%eax, 8(%esp)
	movl	4(%esp), %eax		# old error code
	#TODO sseg
	movl	%eax, 4(%esp)
	popl	%eax
	call	save
	push	%eax			# push exception vector
	call	exception		# exception(vec_nr)
	addl	$4, %esp
	cli
	ret

#*===========================================================================*
#* level0_call *
#*===========================================================================*
level0_call:
	call	save
	jmp	*(_level0_func)

#*===========================================================================*
#* data *
#*===========================================================================*

.data
	.align	4
.globl _idt
.globl _gdt
.globl _level0_func

_idt:	.space	(8+8*IDT_SIZE)	# space for IDT (8 spare bytes at start)
_gdt:	.space	(8+8*GDT_SIZE)	# space for GDT (8 spare bytes at start)

_level0_func:
	.long	0

.bss
	.align	4
.globl k_stack
k_stack:
	.space	K_STACK_BYTES	# kernel stack
k_stktop:			# top of kernel stack

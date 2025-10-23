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

# Headers and constants (use .S preprocessing or define constants manually)
#include <minix/config.h>
#include <minix/const.h>
#include <minix/com.h>
#include <ibm/interrupt.h>
#include "const.h"
#include "protect.h"
#include "sconst.h"

.intel_syntax noprefix

# Sections and section-start labels
.section .text
.globl MINIX
.globl begtext
begtext:
MINIX:                          # entry point for the MINIX kernel
    jmp over_flags              # skip over the next few bytes
    .word CLICK_SHIFT           # for the monitor: memory granularity
flags:
    .word 0x01FD                # boot monitor flags (see original comment)
    nop
over_flags:


# Selected 386 tss offsets
#define TSS3_S_SP0 4

# Exported functions/variables (without underscore prefix)
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

.globl hwint00
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

.globl begbss
.globl begdata

# --------------------------
# Entry/setup
# --------------------------

# Set up a C stack frame on the monitor stack. (Monitor set cs/ds; ss is monitor data.)
    movzx esp, sp               # monitor stack is 16-bit
    push ebp
    mov  ebp, esp
    push esi
    push edi
    cmp  dword ptr [ebp + 4], 0 # monitor return vector nonzero if return possible
    jz   noret
    inc  dword ptr [mon_return]
noret:
    mov  dword ptr [mon_sp], esp

# Copy the monitor GDT into kernel space and switch to it so prot_init() updates take effect.
    sgdt [gdt + GDT_SELECTOR]               # get the monitor GDTR (limit/base written to mem)
    mov  esi, dword ptr [gdt + GDT_SELECTOR + 2]  # absolute address of monitor GDT base
    lea  ebx, [gdt]                         # address of kernel GDT buffer
    mov  ecx, 8*8                           # copy eight descriptors (8 bytes each)
copygdt:
    mov  al, byte ptr es:[esi]
    mov  byte ptr [ebx], al
    inc  esi
    inc  ebx
    loop copygdt

    mov  eax, dword ptr [gdt + DS_SELECTOR + 2]   # base of kernel data (24-bit in descriptor)
    and  eax, 0x00FFFFFF
    add  eax, OFFSET gdt                          # eax = vir2phys(gdt)
    mov  dword ptr [gdt + GDT_SELECTOR + 2], eax  # set base of GDT
    lgdt [gdt + GDT_SELECTOR]                     # switch to kernel GDT

# Locate boot parameters, set up kernel segment registers and stack.
    mov  ebx, dword ptr [ebp + 8]    # boot parameters offset
    mov  edx, dword ptr [ebp + 12]   # boot parameters length
    mov  eax, dword ptr [ebp + 16]   # address of a.out headers
    mov  dword ptr [aout], eax

    mov  ax, ds       # kernel data selector already in ds
    mov  es, ax
    mov  fs, ax
    mov  gs, ax
    mov  ss, ax
    mov  esp, k_stktop

# Call C startup to set up environment for main()
    push edx
    push ebx
    push SS_SELECTOR
    push DS_SELECTOR
    push CS_SELECTOR
    call cstart                     # cstart(cs, ds, mds, parmoff, parmlen)
    add  esp, 5*4

# Reload GDTR/IDTR and segment registers as set by prot_init()
    lgdt [gdt + GDT_SELECTOR]
    lidt [gdt + IDT_SELECTOR]

    ljmp CS_SELECTOR, csinit
csinit:
    mov  ax, DS_SELECTOR
    mov  ds, ax
    mov  es, ax
    mov  fs, ax
    mov  gs, ax
    mov  ss, ax
    mov  ax, TSS_SELECTOR          # no other TSS is used
    ltr  ax

    push 0                         # set EFLAGS to a known state (clear NT/IF as required)
    popf

    jmp main

# --------------------------
# Interrupt handlers
# --------------------------

# Master PIC IRQ handlers (0..7)
.macro hwint_master irq
    call save
    push dword ptr [irq_handlers + 4*\irq]   # irq_handlers[irq]
    call intr_handle
    pop  ecx

    cmp  dword ptr [irq_actids + 4*\irq], 0  # still active?
    jz   0f
    in   al, INT_CTLMASK                     # get current mask
    or   al, (1 << \irq)                     # mask irq
    out  INT_CTLMASK, al                     # disable the irq
0:
    mov  al, END_OF_INT
    out  INT_CTL, al                         # EOI to master 8259
    ret
.endm

# Slave PIC IRQ handlers (8..15)
.macro hwint_slave irq
    call save
    push dword ptr [irq_handlers + 4*\irq]   # irq_handlers[irq]
    call intr_handle
    pop  ecx

    cmp  dword ptr [irq_actids + 4*\irq], 0  # still active?
    jz   0f
    in   al, INT2_CTLMASK
    or   al, (1 << (\irq - 8))
    out  INT2_CTLMASK, al                    # disable the irq on slave
0:
    mov  al, END_OF_INT
    out  INT_CTL,  al                        # EOI to master 8259
    out  INT2_CTL, al                        # EOI to slave 8259
    ret
.endm

.p2align 4
hwint00:    hwint_master 0       # clock
.p2align 4
hwint01:    hwint_master 1       # keyboard
.p2align 4
hwint02:    hwint_master 2       # cascade
.p2align 4
hwint03:    hwint_master 3       # second serial
.p2align 4
hwint04:    hwint_master 4       # first serial
.p2align 4
hwint05:    hwint_master 5       # XT winchester
.p2align 4
hwint06:    hwint_master 6       # floppy
.p2align 4
hwint07:    hwint_master 7       # printer

.p2align 4
hwint08:    hwint_slave 8        # realtime clock
.p2align 4
hwint09:    hwint_slave 9        # irq 2 redirected
.p2align 4
hwint10:    hwint_slave 10
.p2align 4
hwint11:    hwint_slave 11
.p2align 4
hwint12:    hwint_slave 12
.p2align 4
hwint13:    hwint_slave 13       # FPU exception
.p2align 4
hwint14:    hwint_slave 14       # AT winchester
.p2align 4
hwint15:    hwint_slave 15

# --------------------------
# save: save interrupted context (protected mode)
# --------------------------
.p2align 4
save:
    cld
    pushad
    push ds
    push es
    push fs
    push gs

    mov  dx, ss                 # ss is kernel data segment
    mov  ds, dx
    mov  es, dx                 # fs/gs unused by kernel

    mov  eax, esp
    inc  byte ptr [k_reenter]   # from -1 if not reentering
    jnz  set_restart1

    mov  esp, k_stktop
    push OFFSET restart         # build return address for int handler
    xor  ebp, ebp               # for stacktrace
    jmp  dword ptr [eax + (RETADR - P_STACKBASE)]

.p2align 2
set_restart1:
    push OFFSET restart1
    jmp  dword ptr [eax + (RETADR - P_STACKBASE)]

# --------------------------
# s_call / p_s_call: system calls from tasks/processes
# --------------------------
.p2align 4
s_call:
p_s_call:
    cld
    sub  esp, 6*4               # skip RETADR, eax, ecx, edx, ebx, est
    push ebp
    push esi
    push edi
    push ds
    push es
    push fs
    push gs
    mov  dx, ss
    mov  ds, dx
    mov  es, dx
    inc  byte ptr [k_reenter]
    mov  esi, esp               # assumes P_STACKBASE == 0
    mov  esp, k_stktop
    xor  ebp, ebp               # for stacktrace

    # Parameters for sys_call(function, src_dest, m_ptr)
    push ebx                    # m_ptr
    push eax                    # src/dest
    push ecx                    # SEND/RECEIVE/BOTH
    call sys_call
    # caller is now explicitly in proc_ptr
    mov  dword ptr [esi + AXREG], eax   # sys_call must preserve si

    # fallthrough to restart

# --------------------------
# restart current/next process
# --------------------------
restart:
    cmp  dword ptr [next_ptr], 0
    jz   0f
    mov  eax, dword ptr [next_ptr]
    mov  dword ptr [proc_ptr], eax
    mov  dword ptr [next_ptr], 0
0:
    mov  esp, dword ptr [proc_ptr]      # assume P_STACKBASE == 0
    lldt word ptr [esp + P_LDT_SEL]     # enable process' segment descriptors
    lea  eax, [esp + P_STACKTOP]        # arrange TSS.esp0
    mov  dword ptr [tss + TSS3_S_SP0], eax
restart1:
    dec  byte ptr [k_reenter]
    pop  gs
    pop  fs
    pop  es
    pop  ds
    popad
    add  esp, 4                 # skip return address
    iretd

# --------------------------
# exception stubs
# --------------------------
divide_error:            push DIVIDE_VECTOR      ; jmp exception
                         jmp  exception
single_step_exception:   push DEBUG_VECTOR
                         jmp  exception
nmi:                     push NMI_VECTOR
                         jmp  exception
breakpoint_exception:    push BREAKPOINT_VECTOR
                         jmp  exception
overflow:                push OVERFLOW_VECTOR
                         jmp  exception
bounds_check:            push BOUNDS_VECTOR
                         jmp  exception
inval_opcode:            push INVAL_OP_VECTOR
                         jmp  exception
copr_not_available:      push COPROC_NOT_VECTOR
                         jmp  exception
double_fault:            push DOUBLE_FAULT_VECTOR
                         jmp  errexception
copr_seg_overrun:        push COPROC_SEG_VECTOR
                         jmp  exception
inval_tss:               push INVAL_TSS_VECTOR
                         jmp  errexception
segment_not_present:     push SEG_NOT_VECTOR
                         jmp  errexception
stack_exception:         push STACK_FAULT_VECTOR
                         jmp  errexception
general_protection:      push PROTECTION_VECTOR
                         jmp  errexception
page_fault:              push PAGE_FAULT_VECTOR
                         jmp  errexception
copr_error:              push COPROC_ERR_VECTOR
                         jmp  exception

# --------------------------
# exception common (no error code)
# --------------------------
.p2align 4
exception:
    mov  dword ptr [trap_errno], 0
    pop  dword ptr [ex_number]
    jmp  exception1

# --------------------------
# exception with error code
# --------------------------
.p2align 4
errexception:
    pop  dword ptr [ex_number]
    pop  dword ptr [trap_errno]

exception1:
    push eax
    mov  eax, dword ptr [esp + 0 + 4]        # old eip (top after push eax)
    mov  dword ptr [old_eip], eax
    movzx eax, word ptr [esp + 4 + 4]        # old cs
    mov  dword ptr [old_cs], eax
    mov  eax, dword ptr [esp + 8 + 4]        # old eflags
    mov  dword ptr [old_eflags], eax
    pop  eax

    call save
    push dword ptr [old_eflags]
    push dword ptr [old_cs]
    push dword ptr [old_eip]
    push dword ptr [trap_errno]
    push dword ptr [ex_number]
    call exception                 # exception(ex_number, trap_errno, old_eip, old_cs, old_eflags)
    add  esp, 5*4
    ret

# --------------------------
# level0_call
# --------------------------
level0_call:
    call save
    jmp  dword ptr [level0_func]

# --------------------------
# Data-like sections
# --------------------------

.section .rodata
.globl begrom
begrom:
    .word 0x526F                # must be first data entry (magic #)

.section .data
.globl begdata
begdata:

.section .bss
.globl begbss
begbss:
k_stack:
    .space K_STACK_BYTES
k_stktop:

# commons
.comm ex_number, 4
.comm trap_errno, 4
.comm old_eip, 4
.comm old_cs, 4
.comm old_eflags, 4

/*
Notes on key translations:

    ACK .sect mapped to GAS .section, and .data2 mapped to .word; .space and .comm are unchanged.

    The ACK “o16” operand-size prefixes were unnecessary in GAS because explicit 16-bit operands (e.g., mov ax, ...)
    automatically encode the correct prefix in 32-bit mode.

    Segment override helpers eseg/sseg were expressed directly using es: on the memory operand or dropped where DS
    already selects kernel data; e.g., es:[esi] for source in the GDT copy and plain [symbol] for kernel globals.

    The ACK jmpf selector:label was translated to an immediate far jump jmp far CS_SELECTOR:csinit.

    inb/outb pseudo-ops were translated to in/out with AL and immediate/DX ports (e.g., in al, INT_CTLMASK; out INT_CTL, al).

    Memory operands of the form NAME(ebp)/RETADR-P_STACKBASE(eax) were converted to Intel addressing [reg + displacement],
    using dword/word ptr where needed; the jump through a saved return slot is jmp dword ptr [eax + (RETADR - P_STACKBASE)].

    All exported/global symbol names and their references were de-underscored (e.g., _restart→restart,
    _sys_call→sys_call, _exception→exception, etc.).

*/

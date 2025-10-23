.intel_syntax noprefix

# Sections
.section .text
.section .rodata
.section .data
.section .bss

# Includes (assemble as .S or replace with numeric constants)
#include <minix/config.h>
#include <minix/const.h>
#include "const.h"
#include "sconst.h"
#include "protect.h"

# Exported symbols (underscore removed)
.globl monitor
.globl int86
.globl cp_mess
.globl exit
.globl _exit
.globl __exit
.globl __main
.globl phys_insw
.globl phys_insb
.globl phys_outsw
.globl phys_outsb
.globl enable_irq
.globl disable_irq
.globl phys_copy
.globl phys_memset
.globl mem_rdw
.globl reset
.globl idle_task
.globl level0
.globl read_tsc
.globl read_cpu_flags

# --------------------------
# monitor
# PUBLIC void monitor(void);
# --------------------------
monitor:
    mov     esp, dword ptr [mon_sp]
    mov     dx, SS_SELECTOR
    mov     ds, dx
    mov     es, dx
    mov     fs, dx
    mov     gs, dx
    mov     ss, dx
    pop     edi
    pop     esi
    pop     ebp
    data16  retf

# --------------------------
# int86
# PUBLIC void int86(void);
# --------------------------
int86:
    cmp     byte ptr [mon_return], 0
    jnz     0f
    mov     ah, 0x01
    mov     byte ptr [reg86 + 0],  ah
    mov     byte ptr [reg86 + 13], ah
    ret
0:
    push    ebp
    push    esi
    push    edi
    push    ebx
    pushf
    cli

    in      al, INT2_CTLMASK
    mov     ah, al
    in      al, INT_CTLMASK
    push    eax

    mov     eax, dword ptr [irq_use]
    and     eax, ~(1 << CLOCK_IRQ)
    out     INT_CTLMASK, al
    mov     al, ah
    out     INT2_CTLMASK, al

    mov     eax, SS_SELECTOR
    mov     ss,  ax
    xchg    esp, dword ptr [mon_sp]

    # Push parameters used in INT call (saved regs in reg86)
    push    dword ptr [reg86 + 36]
    push    dword ptr [reg86 + 32]
    push    dword ptr [reg86 + 28]
    push    dword ptr [reg86 + 24]
    push    dword ptr [reg86 + 20]
    push    dword ptr [reg86 + 16]
    push    dword ptr [reg86 + 12]
    push    dword ptr [reg86 +  8]
    push    dword ptr [reg86 +  4]
    push    dword ptr [reg86 +  0]

    mov     ds, ax
    mov     es, ax
    mov     fs, ax
    mov     gs, ax

    push    cs
    push    OFFSET return_from_int86
    # Indirect far jump via pointer on stack (16:16)
    # 20 + 2*4 + 10*4 + 2*4 = 76 bytes above current ESP
    data16  ljmp    [esp + (20 + 2*4 + 10*4 + 2*4)]

return_from_int86:
    pop     dword ptr [reg86 +  0]
    pop     dword ptr [reg86 +  4]
    pop     dword ptr [reg86 +  8]
    pop     dword ptr [reg86 + 12]
    pop     dword ptr [reg86 + 16]
    pop     dword ptr [reg86 + 20]
    pop     dword ptr [reg86 + 24]
    pop     dword ptr [reg86 + 28]
    pop     dword ptr [reg86 + 32]
    pop     dword ptr [reg86 + 36]

    lgdt    [gdt + GDT_SELECTOR]
    ljmp    CS_SELECTOR, csinit_int86
csinit_int86:
    mov     eax, DS_SELECTOR
    mov     ds, ax
    mov     es, ax
    mov     fs, ax
    mov     gs, ax
    mov     ss, ax

    xchg    esp, dword ptr [mon_sp]
    lidt    [gdt + IDT_SELECTOR]
    and     byte ptr [gdt + TSS_SELECTOR + DESC_ACCESS], ~0x02
    mov     eax, TSS_SELECTOR
    ltr     ax

    pop     eax
    out     INT_CTLMASK, al
    mov     al, ah
    out     INT2_CTLMASK, al

    add     dword ptr [lost_ticks], ecx

    popf
    pop     ebx
    pop     edi
    pop     esi
    pop     ebp
    ret

# --------------------------
# cp_mess
# PUBLIC void cp_mess(int src, phys_clicks scl, vir_bytes sof,
#                     phys_clicks dcl, vir_bytes dof);
# --------------------------
# Layout after pushes: eip, esi, edi, ds, es => 20 bytes
.set CM_ARGS, (4 + 4 + 4 + 4 + 4)

.p2align 4
cp_mess:
    cld
    push    esi
    push    edi
    push    ds
    push    es

    mov     eax, FLAT_DS_SELECTOR
    mov     ds, ax
    mov     es, ax

    # Compute src and dst linear addresses
    mov     esi, dword ptr [esp + CM_ARGS + 4]        # src clicks
    shl     esi, CLICK_SHIFT
    add     esi, dword ptr [esp + CM_ARGS + 4 + 4]    # src offset
    mov     edi, dword ptr [esp + CM_ARGS + 4 + 4 + 4]# dst clicks
    shl     edi, CLICK_SHIFT
    add     edi, dword ptr [esp + CM_ARGS + 4 + 4 + 4 + 4] # dst offset

    mov     eax, dword ptr [esp + CM_ARGS + 0]        # sender proc
    stosd                                           # store sender in dest
    add     esi, 4
    mov     ecx, Msize - 1
    rep movsd

    pop     es
    pop     ds
    pop     edi
    pop     esi
    ret

# --------------------------
# exit dummies and __main
# --------------------------
exit:
_exit:
__exit:
    sti
    jmp     __exit

__main:
    ret

# --------------------------
# phys_insw
# PUBLIC void phys_insw(Port_t port, phys_bytes buf, size_t count);
# --------------------------
phys_insw:
    push    ebp
    mov     ebp, esp
    cld
    push    edi
    push    es
    mov     ecx, FLAT_DS_SELECTOR
    mov     es, cx
    mov     edx, dword ptr [ebp + 8]
    mov     edi, dword ptr [ebp + 12]
    mov     ecx, dword ptr [ebp + 16]
    shr     ecx, 1
    rep insw                                     # ES:EDI, DX
    pop     es
    pop     edi
    pop     ebp
    ret

# --------------------------
# phys_insb
# PUBLIC void phys_insb(Port_t port, phys_bytes buf, size_t count);
# --------------------------
phys_insb:
    push    ebp
    mov     ebp, esp
    cld
    push    edi
    push    es
    mov     ecx, FLAT_DS_SELECTOR
    mov     es, cx
    mov     edx, dword ptr [ebp + 8]
    mov     edi, dword ptr [ebp + 12]
    mov     ecx, dword ptr [ebp + 16]
    rep insb
    pop     es
    pop     edi
    pop     ebp
    ret

# --------------------------
# phys_outsw
# PUBLIC void phys_outsw(Port_t port, phys_bytes buf, size_t count);
# --------------------------
.p2align 4
phys_outsw:
    push    ebp
    mov     ebp, esp
    cld
    push    esi
    push    ds
    mov     ecx, FLAT_DS_SELECTOR
    mov     ds, cx
    mov     edx, dword ptr [ebp + 8]
    mov     esi, dword ptr [ebp + 12]
    mov     ecx, dword ptr [ebp + 16]
    shr     ecx, 1
    rep outsw                                    # DX, DS:ESI
    pop     ds
    pop     esi
    pop     ebp
    ret

# --------------------------
# phys_outsb
# PUBLIC void phys_outsb(Port_t port, phys_bytes buf, size_t count);
# --------------------------
.p2align 4
phys_outsb:
    push    ebp
    mov     ebp, esp
    cld
    push    esi
    push    ds
    mov     ecx, FLAT_DS_SELECTOR
    mov     ds, cx
    mov     edx, dword ptr [ebp + 8]
    mov     esi, dword ptr [ebp + 12]
    mov     ecx, dword ptr [ebp + 16]
    rep outsb
    pop     ds
    pop     esi
    pop     ebp
    ret

# --------------------------
# enable_irq
# PUBLIC void enable_irq(irq_hook_t *hook);
# --------------------------
.p2align 4
enable_irq:
    push    ebp
    mov     ebp, esp
    pushf
    cli
    mov     eax, dword ptr [ebp + 8]        # hook*
    mov     ecx, dword ptr [eax + 8]        # irq
    mov     eax, dword ptr [eax + 12]       # id bit
    not     eax
    and     dword ptr [irq_actids + ecx*4], eax
    jnz     en_done

    mov     ah, ~1
    rol     ah, cl

    mov     edx, INT_CTLMASK
    cmp     cl, 8
    jb      0f
    mov     edx, INT2_CTLMASK
0:
    in      al, dx
    and     al, ah
    out     dx, al
en_done:
    popf
    leave
    ret

# --------------------------
# disable_irq
# PUBLIC int disable_irq(irq_hook_t *hook);
# --------------------------
.p2align 4
disable_irq:
    push    ebp
    mov     ebp, esp
    pushf
    cli
    mov     eax, dword ptr [ebp + 8]        # hook*
    mov     ecx, dword ptr [eax + 8]        # irq
    mov     eax, dword ptr [eax + 12]       # id bit
    or      dword ptr [irq_actids + ecx*4], eax

    mov     ah, 1
    rol     ah, cl

    mov     edx, INT_CTLMASK
    cmp     cl, 8
    jb      0f
    mov     edx, INT2_CTLMASK
0:
    in      al, dx
    test    al, ah
    jnz     dis_already
    or      al, ah
    out     dx, al
    mov     eax, 1
    popf
    leave
    ret
dis_already:
    xor     eax, eax
    popf
    leave
    ret

# --------------------------
# phys_copy
# PUBLIC void phys_copy(phys_bytes src, phys_bytes dst, phys_bytes len);
# --------------------------
# Stack after pushes: eip, esi, edi, es => 12 bytes
.set PC_ARGS, (4 + 4 + 4 + 4)

.p2align 4
phys_copy:
    cld
    push    esi
    push    edi
    push    es

    mov     eax, FLAT_DS_SELECTOR
    mov     es, ax

    mov     esi, dword ptr [esp + PC_ARGS + 0]   # src
    mov     edi, dword ptr [esp + PC_ARGS + 4]   # dst
    mov     eax, dword ptr [esp + PC_ARGS + 8]   # len

    cmp     eax, 10
    jb      pc_small
    mov     ecx, esi
    neg     ecx
    and     ecx, 3
    sub     eax, ecx
    rep es movsb

    mov     ecx, eax
    shr     ecx, 2
    rep es movsd

    and     eax, 3
pc_small:
    xchg    ecx, eax
    rep es movsb

    pop     es
    pop     edi
    pop     esi
    ret

# --------------------------
# phys_memset
# PUBLIC void phys_memset(phys_bytes dst, unsigned long pattern, phys_bytes len);
# --------------------------
.p2align 4
phys_memset:
    push    ebp
    mov     ebp, esp
    push    esi
    push    ebx
    push    ds

    mov     esi, dword ptr [ebp + 8]        # dst
    mov     eax, dword ptr [ebp + 16]       # len
    mov     ebx, FLAT_DS_SELECTOR
    mov     ds,  bx
    mov     ebx, dword ptr [ebp + 12]       # pattern

    shr     eax, 2
fill_start:
    mov     dword ptr [esi], ebx
    add     esi, 4
    dec     eax
    jnz     fill_start

    mov     eax, dword ptr [ebp + 16]
    and     eax, 3
remain_fill:
    cmp     eax, 0
    jz      fill_done
    mov     bl, byte ptr [ebp + 12]
    mov     byte ptr [esi], bl
    add     esi, 1
    inc     ebp            # keep behavior identical to original
    dec     eax
    jmp     remain_fill
fill_done:
    pop     ds
    pop     ebx
    pop     esi
    pop     ebp
    ret

# --------------------------
# mem_rdw
# PUBLIC u16_t mem_rdw(U16_t segment, u16_t *offset);
# --------------------------
.p2align 4
mem_rdw:
    mov     cx, ds
    mov     ds, word ptr [esp + 4]     # segment
    mov     eax, dword ptr [esp + 8]   # pointer to word
    movzx   eax, word ptr [eax]
    mov     ds, cx
    ret

# --------------------------
# reset
# PUBLIC void reset(void);
# --------------------------
reset:
    lidt    [idt_zero]
    int     3

.section .data
    .align 4
idt_zero:
    .long 0, 0

.section .text

# --------------------------
# idle_task
# PUBLIC void idle_task(void);
# --------------------------
idle_task:
    push    OFFSET halt
    call    level0
    pop     eax
    jmp     idle_task
halt:
    sti
    hlt
    cli
    ret

# --------------------------
# level0
# PUBLIC void level0(void (*func)(void));
# --------------------------
level0:
    mov     eax, dword ptr [esp + 4]
    mov     dword ptr [level0_func], eax
    int     LEVEL0_VECTOR
    ret

# --------------------------
# read_tsc
# PUBLIC void read_tsc(unsigned long *high, unsigned long *low);
# --------------------------
.p2align 4
read_tsc:
    rdtsc
    push    ebp
    mov     ebp, dword ptr [esp + 8]   # &high
    mov     dword ptr [ebp], edx
    mov     ebp, dword ptr [esp + 12]  # &low
    mov     dword ptr [ebp], eax
    pop     ebp
    ret

# --------------------------
# read_cpu_flags
# PUBLIC unsigned long read_cpu_flags(void);
# --------------------------
.p2align 4
read_cpu_flags:
    pushf
    mov     eax, dword ptr [esp]
    popf
    ret

/*
Notes:

The far jump back into protected mode is written as “ljmp CS_SELECTOR, csinit_int86”, and the 16:16 indirect far jump uses
“data16 ljmp [mem]” to force a 16‑bit offset in the pointer.

For string copies in phys_copy, ES overrides on MOVS ensure the source also uses ES, which matches the original “eseg movs*” intent.

Using “push OFFSET label” when passing a code pointer (e.g., halt) makes GAS load the address instead of dereferencing the symbol.
                 ​
*/

#include <stdint.h>

void intr_disable(void) {
    __asm__ __volatile__("cli" ::: "memory");
}

void intr_enable(void) {
    __asm__ __volatile__("sti" ::: "memory");
}


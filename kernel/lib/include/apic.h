#ifndef APIC_H
#define APIC_H

#include <stdint.h>

struct cpuid_result
{
    uint32_t eax;
    uint32_t ebx;
    uint32_t ecx;
    uint32_t edx;
};

//cool define z neta

#define IA32_APIC_BASE_MSR 0x1B
#define APIC_REG_ID        0x020
#define APIC_REG_VERSION   0x030
#define APIC_REG_TPR       0x080
#define APIC_REG_EOI       0x0B0
#define APIC_REG_SVR       0x0F0

#define APIC_REG_LVT_TIMER 0x320
#define APIC_REG_LVT_THERMAL 0x330
#define APIC_REG_LVT_PERF  0x340
#define APIC_REG_LVT_LINT0 0x350
#define APIC_REG_LVT_LINT1 0x360
#define APIC_REG_LVT_ERROR 0x370

#define APIC_SVR_ENABLE       (1U << 8)
#define APIC_LVT_MASKED       (1U << 16)
#define APIC_SPURIOUS_VECTOR  0xFF

void apic_cpuid(uint32_t leaf, struct cpuid_result *result);
uint64_t apic_rdmsr(uint32_t msr);
void apic_wrmsr(uint32_t msr, uint64_t value);

void apic_init(void);

//4 unsigned int 1.eax 2.ebx 3.ecx 4.edx i tablica ma miec 4 sloty
void cpuid(uint32_t leaf, uint32_t *tab);
//tablixa ma miec 2 sloty 1 to ID a drugi version
void lapic_info(uint32_t *tab);

#endif
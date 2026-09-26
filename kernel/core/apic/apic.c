#include "apic.h"
#include "serial.h"

extern uint32_t apic_cpuid(uint32_t leaf);
extern uint64_t apic_rdmsr(uint32_t msr);
extern void apic_wrmsr(uint32_t msr, uint64_t value);

void apic_init(void)
{
    serial_write("APIC init\r\n");

    uint32_t eax = apic_cpuid(1);

    serial_write("CPUID.1 EAX: ");
    serial_write_hex(eax);
    serial_write("\r\n");
}
#include "apic.h"
#include "serial.h"

extern void apic_cpuid(uint32_t leaf, struct cpuid_result *result);
extern uint64_t apic_rdmsr(uint32_t msr);
extern void apic_wrmsr(uint32_t msr, uint64_t value);

static volatile uint32_t *lapic;

static uint32_t apic_read(uint32_t offset)
{
    return lapic[offset / 4];
}

static void apic_write(uint32_t offset, uint32_t value)
{
    lapic[offset / 4] = value;
}

//4 unsigned int 1.eax 2.ebx 3.ecx 4.edx i tablica ma miec 4 sloty
void cpuid(uint32_t leaf, uint32_t *tab) {
    apic_cpuid(leaf, (struct cpuid_result *)tab);
}

//tablixa ma miec 2 sloty 1 to ID a drugi version
void lapic_info(uint32_t *tab){
    *tab = apic_read(APIC_REG_ID);
    *(tab + 1) = apic_read(APIC_REG_VERSION);
}

void apic_init(void)
{
    struct cpuid_result cpuid;

    serial_write("APIC init\n");

    apic_cpuid(1, &cpuid);

    serial_write("CPUID.1 EAX: ");
    serial_write_hex(cpuid.eax);
    serial_write("\n");

    serial_write("CPUID.1 EDX: ");
    serial_write_hex(cpuid.edx);
    serial_write("\n");

    if (!(cpuid.edx & (1 << 9)))
    {
        serial_write("Local APIC unavailable\r\n");
        return;
    }
    uint64_t apic_base = apic_rdmsr(IA32_APIC_BASE_MSR);

    serial_write("IA32_APIC_BASE: ");
    serial_write_hex(apic_base);
    serial_write("\n");

    serial_write("Local APIC available\n");

    serial_write("IA32_APIC_BASE: ");
    serial_write_hex(apic_base);
    serial_write("\n");

    lapic = (volatile uint32_t *)(uintptr_t)0xFEE00000;

    uint32_t apic_id = apic_read(APIC_REG_ID);
    uint32_t apic_version = apic_read(APIC_REG_VERSION);

    serial_write("LAPIC ID: ");
    serial_write_hex(apic_id);
    serial_write("\n");

    serial_write("LAPIC VERSION: ");
    serial_write_hex(apic_version);
    serial_write("\n");

    serial_write("Local APIC available\n");
    

    /*
0x320  Timer
0x330  Thermal
0x340  Performance Counter
0x350  LINT0
0x360  LINT1
0x370  Error
    */
    apic_write(0x320, APIC_LVT_MASKED);
    apic_write(0x330, APIC_LVT_MASKED);
    apic_write(0x340, APIC_LVT_MASKED);
    apic_write(0x350, APIC_LVT_MASKED);
    apic_write(0x360, APIC_LVT_MASKED);
    apic_write(0x370, APIC_LVT_MASKED);

    uint32_t svr = APIC_SPURIOUS_VECTOR | APIC_SVR_ENABLE;

    apic_write(APIC_REG_SVR, svr);

    uint32_t svr_read = apic_read(APIC_REG_SVR);

    serial_write("LAPIC SVR: ");
    serial_write_hex(svr_read);
    serial_write("\r\n");
}
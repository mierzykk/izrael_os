#include "gdt.h"
#include "serial.h"

static uint64_t gdt[7];
static struct gdtr gdtr;
static struct TSS tss;

static void encodeGdtEntry(uint8_t *target, const struct GDT *gdt)
{
    if (gdt->limit > 0xFFFFF) {serial_write("GDT cannot encode limits larger than 0xFFFFF");}

    // Encode the limit
    target[0] = gdt->limit & 0xFF;
    target[1] = (gdt->limit >> 8) & 0xFF;
    target[6] = (gdt->limit >> 16) & 0x0F;

    // Encode the base
    target[2] = gdt->base & 0xFF;
    target[3] = (gdt->base >> 8) & 0xFF;
    target[4] = (gdt->base >> 16) & 0xFF;
    target[7] = (gdt->base >> 24) & 0xFF;

    // Encode the access byte
    target[5] = gdt->access_byte;

    // Encode the flags
    target[6] |= (gdt->flags << 4);
}

static void gdt_set_entry(
    uint8_t *target,
    uint32_t base,
    uint32_t limit,
    uint8_t access,
    uint8_t flags
){
    struct GDT gdt;
    gdt.base = base;
    gdt.limit = limit;
    gdt.access_byte = access;
    gdt.flags = flags;

    encodeGdtEntry(target, &gdt);
}

static void tss_set_descriptor(void)
{
    uint64_t base = (uint64_t)&tss;
    uint64_t limit = sizeof(tss) - 1;

    uint64_t low = 0;
    uint64_t high = 0;

    low |= limit & 0xFFFF;
    low |= (base & 0xFFFFFF) << 16;
    low |= 0x89ULL << 40;
    low |= ((limit >> 16) & 0xF) << 48;
    low |= ((base >> 24) & 0xFF) << 56;

    high = base >> 32;

    gdt[5] = low;
    gdt[6] = high;
    
}

void gdt_init(void)
{
    // ring 0
    gdt_set_entry((uint8_t *)&gdt[1], 0, 0xFFFFF, 0x9A, 0xA);
    gdt_set_entry((uint8_t *)&gdt[2], 0, 0xFFFFF, 0x92, 0xC);

    // ring 3
    gdt_set_entry((uint8_t *)&gdt[3], 0, 0xFFFFF, 0xFA, 0xA);
    gdt_set_entry((uint8_t *)&gdt[4], 0, 0xFFFFF, 0xF2, 0xC);

    // TSS
    tss.rsp0 = 0x90000;
    tss.iomap_base = sizeof(tss);

    tss_set_descriptor();

    // GDTR
    gdtr.base = (uint64_t)gdt;
    gdtr.limit = sizeof(gdt) - 1;

    // Załaduj nową GDT
    gdt_load(&gdtr);

    // Odśwież CS i segmenty
    gdt_reload_cs();
    gdt_reload_data_segments();

    // Załaduj TSS
    tss_load(0x28);
}
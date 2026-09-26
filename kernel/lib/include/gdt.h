#ifndef GDT_H
#define GDT_H

#include <stdint.h>

struct GDT
{
    uint32_t base;
    uint32_t limit;
    uint8_t access_byte;
    uint8_t flags;
};

struct TSS {
    uint32_t reserved0;
    uint64_t rsp0;
    uint64_t rsp1;
    uint64_t rsp2;
    uint64_t reserved1;
    uint64_t ist1;
    uint64_t ist2;
    uint64_t ist3;
    uint64_t ist4;
    uint64_t ist5;
    uint64_t ist6;
    uint64_t ist7;
    uint32_t reserved2;
    uint32_t reserved3;
    uint16_t iomap_base;
} __attribute__((packed));

struct gdtr
{
    uint16_t limit;
    uint64_t base;
} __attribute__((packed));

void gdt_init(void);
void gdt_load(const struct gdtr *gdtr);
void gdt_reload_cs(void);
void gdt_reload_data_segments(void);
void tss_load(uint16_t selector);



#endif
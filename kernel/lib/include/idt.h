#ifndef IDT_H
#define IDT_H

#include <stdint.h>

struct idt_entry
{
    uint16_t offset_low;
    uint16_t selector;
    uint8_t  ist;
    uint8_t  attributes;
    uint16_t offset_mid;
    uint32_t offset_high;
    uint32_t reserved;
};

struct idtr
{
    uint16_t limit;
    uint64_t base;
} __attribute__((packed));

struct interrupt_frame
{
    uint64_t vector;
    uint64_t error_code;

    uint64_t rip;
    uint64_t cs;
    uint64_t rflags;

    uint64_t rsp;
    uint64_t ss;
};

void idt_init(void);
void idt_load(const struct idtr *idtr);
void exception_handler(struct interrupt_frame *frame);

#endif
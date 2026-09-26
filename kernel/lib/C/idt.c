#include "idt.h"
#include "panic.h"
#include "serial.h"

typedef void (*idt_handler_t)(void);

extern void isr_0_de(void);
extern void isr_1_db(void);
extern void isr_2_nmi(void);
extern void isr_3_bp(void);
extern void isr_4_of(void);
extern void isr_5_br(void);
extern void isr_6_ud(void);
extern void isr_7_nm(void);
extern void isr_8_df(void);
extern void isr_10_ts(void);
extern void isr_11_np(void);
extern void isr_12_ss(void);
extern void isr_13_gp(void);
extern void isr_14_pf(void);
extern void isr_16_mf(void);
extern void isr_17_ac(void);
extern void isr_18_mc(void);
extern void isr_19_xm(void);
extern void isr_20_ve(void);
extern void isr_21_cp(void);
extern void isr_reserved(void);
extern void isr_32_irq0(void);

_Static_assert(sizeof(struct idt_entry) == 16, "Invalid IDT entry size");
_Static_assert(sizeof(struct idtr) == 10, "Invalid IDTR size");

static struct idt_entry idt[256];
static struct idtr idtr;

static void idt_set_entry(
    uint8_t vector,
    idt_handler_t handler,
    uint16_t selector,
    uint8_t ist,
    uint8_t attributes
)
{
    uintptr_t address = (uintptr_t)handler;

    idt[vector].offset_low = address & 0xFFFF;
    idt[vector].selector = selector;
    idt[vector].ist = ist;
    idt[vector].attributes = attributes;
    idt[vector].offset_mid = (address >> 16) & 0xFFFF;
    idt[vector].offset_high = (address >> 32) & 0xFFFFFFFF;
    idt[vector].reserved = 0;
}

void idt_init(void)
{
    idt_set_entry(0,  isr_0_de,       0x08, 0, 0x8E);
    idt_set_entry(1,  isr_1_db,       0x08, 0, 0x8E);
    idt_set_entry(2,  isr_2_nmi,      0x08, 0, 0x8E);
    idt_set_entry(3,  isr_3_bp,       0x08, 0, 0xEE);
    idt_set_entry(4,  isr_4_of,       0x08, 0, 0xEE);
    idt_set_entry(5,  isr_5_br,       0x08, 0, 0x8E);
    idt_set_entry(6,  isr_6_ud,       0x08, 0, 0x8E);
    idt_set_entry(7,  isr_7_nm,       0x08, 0, 0x8E);

    idt_set_entry(8,  isr_8_df,       0x08, 0, 0x8E);

    idt_set_entry(9,  isr_reserved,   0x08, 0, 0x8E);
    idt_set_entry(10, isr_10_ts,      0x08, 0, 0x8E);
    idt_set_entry(11, isr_11_np,      0x08, 0, 0x8E);
    idt_set_entry(12, isr_12_ss,      0x08, 0, 0x8E);
    idt_set_entry(13, isr_13_gp,      0x08, 0, 0x8E);
    idt_set_entry(14, isr_14_pf,      0x08, 0, 0x8E);

    idt_set_entry(15, isr_reserved,   0x08, 0, 0x8E);

    idt_set_entry(16, isr_16_mf,      0x08, 0, 0x8E);
    idt_set_entry(17, isr_17_ac,      0x08, 0, 0x8E);
    idt_set_entry(18, isr_18_mc,      0x08, 0, 0x8E);
    idt_set_entry(19, isr_19_xm,      0x08, 0, 0x8E);
    idt_set_entry(20, isr_20_ve,      0x08, 0, 0x8E);
    idt_set_entry(21, isr_21_cp,      0x08, 0, 0x8E);

    for (int i = 0; i < 10; i++) {
        idt_set_entry(22 + i, isr_reserved, 0x08, 0, 0x8E);
    }

    idt_set_entry(32, isr_32_irq0, 0x08, 0, 0x8E);

    idtr.base = (uintptr_t)&idt[0];
    idtr.limit = sizeof(idt) - 1;

    idt_load(&idtr);
}

void exception_handler(struct interrupt_frame *frame)
{
    serial_write("EXCEPTION\r\n");

    serial_write("vector: ");
    serial_write_hex(frame->vector);
    serial_write("\r\n");

    serial_write("error: ");
    serial_write_hex(frame->error_code);
    serial_write("\r\n");

    serial_write("rip: ");
    serial_write_hex(frame->rip);
    serial_write("\r\n");

    serial_write("cs: ");
    serial_write_hex(frame->cs);
    serial_write("\r\n");

    serial_write("rflags: ");
    serial_write_hex(frame->rflags);
    serial_write("\r\n");

    serial_write("rsp: ");
    serial_write_hex(frame->rsp);
    serial_write("\r\n");

    serial_write("ss: ");
    serial_write_hex(frame->ss);
    serial_write("\r\n");
    panic("idt fault",0);
    
}
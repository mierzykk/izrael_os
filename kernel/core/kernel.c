#include "serial.h"
#include "gdt.h"
#include "idt.h"
#include "apic.h"

char initsystem(void){
    serial_init();
    clear();
    serial_write("zaladowano serial\n");

    serial_write("laduje gdt\n");
    gdt_init();
    serial_write("zaladowano gdt\n");

    serial_write("laduje idt\n");
    idt_init();
    serial_write("zaladowano idt\n");

    serial_write("laduje apic\n");
    apic_init();
    serial_write("zaladowano apic\n");


    return 0;
}

void maink(void)
{
    (void)initsystem();
}
#include "acpi.h"
#include "panic.h"
#include "serial.h"

_Static_assert(sizeof(struct acpi_rsdp) == 36, "Invalid RSDP size");

char sumakontrolna(uintptr_t aktualnemiejsce){
    
    //musi sie rownac 256 wtedy sie zawija do 0
    uint8_t sum = 0;
    for (int i = 0; i<20; i++){
        sum += *(uint8_t*)(aktualnemiejsce + i);
    }
    if(sum == 0) return 0;
    else return 1;
}

uint32_t find_rsdp(void){
    uint16_t ebdatest = (*(uint16_t *)0x40E);
    if (ebdatest != 0) {
    uintptr_t ebda_poczarwk = ((uintptr_t)ebdatest) << 4;
    uintptr_t ebdakoniec = ebda_poczarwk + 1024;
    

    //ebda
    for (uintptr_t aktualnemiejsce = ebda_poczarwk; aktualnemiejsce < ebdakoniec; aktualnemiejsce += 16){
        if(
            *(uint8_t*)aktualnemiejsce == 'R' &&
            *(uint8_t*)(aktualnemiejsce + 1) == 'S' &&
            *(uint8_t*)(aktualnemiejsce + 2) == 'D' &&
            *(uint8_t*)(aktualnemiejsce + 3) == ' ' &&
            *(uint8_t*)(aktualnemiejsce + 4) == 'P' &&
            *(uint8_t*)(aktualnemiejsce + 5) == 'T' &&
            *(uint8_t*)(aktualnemiejsce + 6) == 'R' &&
            *(uint8_t*)(aktualnemiejsce + 7) == ' '
        ){
            char wynik = sumakontrolna(aktualnemiejsce);
            if(wynik == 0) return (uint32_t)aktualnemiejsce;
        }
    }
}
    uint32_t poczatek = 0xE0000;
    uint32_t koniec =  0x100000;
    //pamiec 
    for (uintptr_t aktualnemiejsce = poczatek; aktualnemiejsce < koniec; aktualnemiejsce += 16){
        if(
            *(uint8_t*)aktualnemiejsce == 'R' &&
            *(uint8_t*)(aktualnemiejsce + 1) == 'S' &&
            *(uint8_t*)(aktualnemiejsce + 2) == 'D' &&
            *(uint8_t*)(aktualnemiejsce + 3) == ' ' &&
            *(uint8_t*)(aktualnemiejsce + 4) == 'P' &&
            *(uint8_t*)(aktualnemiejsce + 5) == 'T' &&
            *(uint8_t*)(aktualnemiejsce + 6) == 'R' &&
            *(uint8_t*)(aktualnemiejsce + 7) == ' '
        ){
            char wynik = sumakontrolna(aktualnemiejsce);
            if(wynik == 0) return (uint32_t)aktualnemiejsce;
        }
    }

    panic("nie znaleziono rsdp", 1);


}

void rsdp_init(void){
    uintptr_t adres = find_rsdp();
    struct acpi_rsdp *rsdp =
        (struct acpi_rsdp *)adres;
    
    serial_write("revision: ");
    serial_write_uint(rsdp->revision);
    serial_write("\n");

    serial_write("oemid: ");
    serial_write(rsdp->oemid);
    serial_write("\n");

    serial_write("rsdt_address: ");
    serial_write_hex(rsdp->rsdt_address);
    serial_write("\n");

    if (rsdp->revision != 0){
    serial_write("length: ");
    serial_write_uint(rsdp->length);
    serial_write("\n");

    serial_write("xsdt_address: ");
    serial_write_hex(rsdp->xsdt_address);
    serial_write("\n");
    
    serial_write("ta wersja acpi nie jest wspierana bedzie uzywana stara wersja 1.0");
}
    //serial_write((uint64_t *)rsdp->rsdt_address);


}


void acpi_init(void){
    rsdp_init();
}
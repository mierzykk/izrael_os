#include "map_memory.h"
#include "serial.h"
#include <stdint.h>

void map_memory_init(){
    map_page(0x1FFE1C40, 0);
}

void map_page(uint64_t virtual, uint64_t physical){
    uint64_t pml4index = (virtual >> 39) & 0x1FF;
    uint64_t pdptindex = (virtual >> 30) & 0x1FF;
    uint64_t pdindex = (virtual >> 21) & 0x1FF;
    uint64_t ptindex = (virtual >> 12) & 0x1FF;
    uint64_t offset = virtual & 0xFFF;

    uint64_t pml4adrespoczatek = 0x1000;
    uint64_t pdptadrespoczatek;
    uint64_t pdadrespoczatek;
    uint64_t ptadrespoczatek;

    uintptr_t pml4adres = pml4adrespoczatek + (pml4index * 8);
    uint64_t adrespml4bezflag = (*(uint64_t *)pml4adres & ~(0xFFF));
    pdptadrespoczatek = adrespml4bezflag;

    uintptr_t pdptadres = pdptadrespoczatek + (pdptindex * 8);
    uint64_t adrespdptbezflag = (*(uint64_t *)pdptadres & ~(0xFFF));
    pdadrespoczatek = adrespdptbezflag;

    uintptr_t pdadres = pdadrespoczatek + (pdindex * 8);

    if (*(uint64_t *)pdadres == 0) {
        *(uint64_t *)pdadres = 0x5000 | 1 << 1 | 1 << 0; //bit present i writable
        ptadrespoczatek = 0x5000;
    }
    else {
        uint64_t adrespdbezflag = (*(uint64_t *)pdadres & ~(0xFFF));
        ptadrespoczatek = adrespdbezflag;
    }

    uintptr_t ptadres = ptadrespoczatek + (ptindex * 8);
    *(uint64_t *)ptadres = physical | 1 << 1 | 1 << 0; //bit present i writable
    //uint64_t adresptbezflag = (*(uint64_t *)ptadres & ~(0xFFF));



    serial_write_hex(*(uint64_t *)pml4adres);
    serial_write("\n");
    serial_write_hex(*(uint64_t *)pdptadres);
    serial_write("\n");
    serial_write_hex(*(uint64_t *)pdadres);
    serial_write("\n");
    serial_write_hex(*(uint64_t *)ptadres);
    serial_write("\n");

}
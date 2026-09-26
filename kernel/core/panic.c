#include "serial.h"

//1arg message //czy clear 0 albo 1
void panic(const char *text, char czysc){
    if(czysc) {
        serial_write("\033[31m");
        clear();
    }
    __asm__ volatile ("cli");
    serial_write(text);
    for (;;) __asm__ volatile ("hlt");

}


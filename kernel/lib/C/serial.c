#include "IO.h"
#include <stdint.h>
#include <serial.h>
#include <stddef.h>
#define PORT 0x3f8          // COM1

static size_t vga_row = 0;
static size_t vga_col = 0;


void serial_init(void){
    outb(PORT + 1, 0x00); //wylaczenie przerwan do zmiany kiedy zaczne obslugiwac przerwania
    outb(PORT + 3, 0x80); //wlaczenie dlab (do konfiguracji init na koncu wylacze)
    outb(PORT, 0x01); //maksymalna predkosc
    outb(PORT + 1, 0x00); // starszy bit dzielnika ustawiony na 0 dla szybkoscis
    outb(PORT + 3, 0x03); //wylaczenie dlab i ustawienie standardu 8 bit danych
    outb(PORT + 2, 0x07); //fifo nic waznego
    outb(PORT + 4, 0x0B); //ustawienie do normalnej pracy
    //nie testuje bo na quemu zawsze dziala jezeli bym robil pod bare metal zrobie test
}

void serial_putc(char c){

    //konsola
    while ((inb(PORT + 5) & 0x20) == 0); //czekanie az bufor sie zwolni
    outb(PORT,c);
    //wysylanie litery

    //okno
    if (c == '\n') {
        vga_col = 0;
        vga_row++;
    } else if (c == '\r') {
        vga_col = 0;
    } else {
        // okno VGA
        volatile unsigned char *p = (volatile unsigned char *)(0xB8000 + ((vga_row * 80 + vga_col) * 2));
        *p = c;
        *(p + 1) = 0x07;

        vga_col++;
        if (vga_col >= 80) {
            vga_col = 0;
            vga_row++;
        }
        if (vga_row >= 25) {
            clear();
        }
    }
}


void clear(void) {
    //dla debug nie czyszcze terminala
    //serial_write("\033[2J\033[H");

    volatile unsigned char *p = (volatile unsigned char *)0xB8000;
    
    for (int i = 0; i < 80 * 25; i++) {
        p[i * 2] = ' ';
        p[i * 2 + 1] = 0x07;
    }
    
    vga_row = 0;
    vga_col = 0;
}


//wypisanie ciagu znakow
void serial_write(const char *text) {
    while (*text != '\0') {
        serial_putc(*text);
        text++;
    }
}


static char hex_digit(uint8_t value){
    if (value < 10) return '0' + value;
    else return 'A' + (value - 10);
}

void serial_write_hex(uint64_t value){
    uint8_t digit;
    for (size_t i=0; i < sizeof(uint64_t)*(8/4);i++){ //16 razy
        digit = (value >> (60-(i*4))) & 0xF;
        serial_putc(hex_digit(digit));
    }
}

void serial_write_uint(uint64_t value){
    if (value == 0) {
        serial_write("0");
        return;
        }

    int index=0;
    char lista[21]; //maksymalna ilosc cyfr 20 + 1 \0

    while (value != 0)
    {
        lista[index] = '0' + (value % 10);
        value /=10;
        index++;
    }
    lista[index] = '\0';

    //odwrocenie listy
    for (int i = 0; i < index / 2; i++) {
        char temp = lista[i];
        lista[i] = lista[index - 1 - i];
        lista[index - 1 - i] = temp;
    }
    serial_write(lista);
    
}



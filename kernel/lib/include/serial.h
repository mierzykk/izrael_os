#ifndef SERIAL_H
#define SERIAL_H

#include <stdint.h>

void serial_init(void);
void serial_putc(char c);
void clear(void);
void serial_write(const char *text);
void serial_write_uint(uint64_t value);
void serial_write_hex(uint64_t value);


#endif
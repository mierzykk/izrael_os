#ifndef ACPI
#define ACPI

#include <stdint.h>

#pragma pack(push, 1)
struct acpi_rsdp
{
    char signature[8];
    uint8_t checksum;
    char oemid[6];
    uint8_t revision;
    uint32_t rsdt_address;

    uint32_t length;
    uint64_t xsdt_address;
    uint8_t extended_checksum;
    uint8_t reserved[3];
};
#pragma pack(pop)

void acpi_init(void);
void rsdp_init(void);

#endif
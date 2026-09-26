[BITS 16]
[ORG 0x7C00]

BOOT_STACK          equ 0x7C00

PML4_ADDR           equ 0x1000
PDPT_ADDR           equ 0x2000
PD_ADDR             equ 0x3000
PT_ADDR             equ 0x4000

PAGE_SIZE           equ 0x1000
PT_ENTRIES          equ 512

PT_PRESENT          equ 1 << 0
PT_WRITABLE         equ 1 << 1

PT_ADDR_MASK        equ 0xFFFFF000


CR0_PE              equ 1 << 0
CR0_PG              equ 1 << 31

CR4_PAE             equ 1 << 5

EFER_MSR            equ 0xC0000080
EFER_LME            equ 1 << 8

CODE32_SEL          equ 0x08
DATA32_SEL          equ 0x10

CODE64_SEL          equ 0x08
DATA64_SEL          equ 0x10


start:
    cli
    cld

    xor ax, ax

    mov ss, ax
    mov sp, BOOT_STACK

    mov ds, ax
    mov es, ax

    mov [boot_drive], dl

    call load_stage2
    jc boot_error


    xor ax, ax
    mov ds, ax
    mov es, ax

    call enter_protected_mode


load_stage2:
    xor ax, ax
    mov es, ax

    mov bx, KERNEL_LOAD_ADDR

    mov ah, 0x02
    mov al, KERNEL_SECTORS

    xor ch, ch
    mov cl, KERNEL_LBA + 1

    xor dh, dh
    mov dl, [boot_drive]

    int 0x13

    ret


enter_protected_mode:

    lgdt [gdtr32]


    mov eax, cr0
    or eax, CR0_PE
    mov cr0, eax

    jmp CODE32_SEL:protected_mode

[BITS 32]

protected_mode:

    mov ax, DATA32_SEL

    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    mov esp, 0x90000

    call setup_page_tables

    call enter_long_mode

setup_page_tables:

    mov edi, PML4_ADDR
    xor eax, eax
    mov ecx, 4096
    rep stosd


    mov edi, PML4_ADDR
    mov eax, PDPT_ADDR | PT_PRESENT | PT_WRITABLE
    mov [edi], eax


    mov edi, PDPT_ADDR
    mov eax, PD_ADDR | PT_PRESENT | PT_WRITABLE
    mov [edi], eax


    mov edi, PD_ADDR
    mov eax, PT_ADDR | PT_PRESENT | PT_WRITABLE
    mov [edi], eax


    mov edi, PT_ADDR

    xor ebx, ebx

    mov eax, PT_PRESENT | PT_WRITABLE
    mov ecx, PT_ENTRIES

.map_page:

    mov [edi], eax

    add eax, PAGE_SIZE
    add edi, 8

    loop .map_page


    mov eax, PML4_ADDR
    mov cr3, eax

    ret


enter_long_mode:

    mov eax, cr4
    or eax, CR4_PAE
    mov cr4, eax

    mov ecx, EFER_MSR
    rdmsr

    or eax, EFER_LME

    wrmsr

    mov eax, cr0
    or eax, CR0_PG
    mov cr0, eax


    lgdt [gdtr64]

    jmp CODE64_SEL:long_mode


[BITS 64]

long_mode:

    mov ax, DATA64_SEL

    mov ds, ax
    mov es, ax
    mov ss, ax


    mov rsp, 0x90000

    ;bardzo zaawansowany debug
    mov byte [0xB8502], 'C'
    mov byte [0xB8503], 0x07


    mov rax, KERNEL_LOAD_ADDR
    jmp rax


[BITS 16]

gdt32:

    dq 0x0000000000000000           ; 0x00 null
    dq 0x00CF9A000000FFFF           ; 0x08 32-bit code
    dq 0x00CF92000000FFFF           ; 0x10 32-bit data

gdt32_end:


gdtr32:
    dw gdt32_end - gdt32 - 1
    dd gdt32


gdt64:

    dq 0x0000000000000000           ; 0x00 null
    dq 0x00AF9A000000FFFF           ; 0x08 64-bit code, L=1
    dq 0x00CF92000000FFFF           ; 0x10 data

gdt64_end:


gdtr64:
    dw gdt64_end - gdt64 - 1
    dd gdt64


boot_error:

    mov ax, 0xB800
    mov es, ax

    xor di, di
    mov word [es:di], 0x0746

.hang:
    cli
    hlt
    jmp .hang


boot_drive:
    db 0


times 510 - ($ - $$) db 0
dw 0xAA55

[BITS 16]
[ORG 0x7C00]

APIC_BASE           equ 0xFEE00000

PT_PAGE_SIZE_2M    equ 1 << 7
PT_CACHE_DISABLE   equ 1 << 4


BOOT_STACK          equ 0x7C00

PML4_ADDR           equ 0x1000
PDPT_ADDR           equ 0x2000
PD_ADDR             equ 0x3000
PT_ADDR             equ 0x4000
PT_EXTRA_ADDR       equ 0x5000

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


; =============================================================================
; PROTECTED MODE
; =============================================================================

[BITS 32]

protected_mode:

    ; -------------------------------------------------------------------------
    ; Załaduj segment danych.
    ; -------------------------------------------------------------------------

    mov ax, DATA32_SEL

    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    mov esp, 0x90000


    ; -------------------------------------------------------------------------
    ; Przygotuj pamięć stronicowaną.
    ; -------------------------------------------------------------------------

    call setup_page_tables


    ; -------------------------------------------------------------------------
    ; Włącz long mode.
    ; -------------------------------------------------------------------------

    call enter_long_mode


; =============================================================================
; PROTECTED MODE
;
; Tworzymy prostą mapę 1:1:
;
;   virtual 0x00000000 -> physical 0x00000000
;   virtual 0x00001000 -> physical 0x00001000
;   ...
;   virtual 0x001FF000 -> physical 0x001FF000
;
; Czyli pierwsze 2 MiB.
;
; To wystarcza bootloaderowi, kernelowi pod 0x8000 i stosowi pod 0x90000.
; =============================================================================

setup_page_tables:

    ; -------------------------------------------------------------------------
    ; Wyczyść:
    ;
    ;   PML4  = 0x1000
    ;   PDPT  = 0x2000
    ;   PD    = 0x3000
    ;   PT    = 0x4000
    ;   rez   = 0x5000 
    ;
    ; Razem 20 KiB = 5120 DWORD-ów.
    ; -------------------------------------------------------------------------

    mov edi, PML4_ADDR
    xor eax, eax
    mov ecx, 5120
    rep stosd


    ; -------------------------------------------------------------------------
    ; PML4[0] -> PDPT
    ; -------------------------------------------------------------------------

    mov edi, PML4_ADDR
    mov eax, PDPT_ADDR | PT_PRESENT | PT_WRITABLE
    mov [edi], eax


    ; -------------------------------------------------------------------------
    ; PDPT[0] -> PD
    ; -------------------------------------------------------------------------

    mov edi, PDPT_ADDR
    mov eax, PD_ADDR | PT_PRESENT | PT_WRITABLE
    mov [edi], eax

    ; -------------------------------------------------------------------------
    ; PDPT[3] -> PD
    ;
    ; 0xFEE00000 znajduje się w obszarze obsługiwanym przez PDPT[3].
    ; Używamy tego samego PD, aby nie tworzyć kolejnej tablicy.
    ; -------------------------------------------------------------------------

    mov edi, PDPT_ADDR
    mov eax, PD_ADDR | PT_PRESENT | PT_WRITABLE
    mov [edi + 3 * 8], eax


    ; -------------------------------------------------------------------------
    ; PD[0] -> PT
    ; -------------------------------------------------------------------------

    mov edi, PD_ADDR
    mov eax, PT_ADDR | PT_PRESENT | PT_WRITABLE
    mov [edi], eax


    ; -------------------------------------------------------------------------
    ; PD[503] -> 2 MiB APIC mapping
    ;
    ;   0xFEE00000 -> 0xFEE00000
    ; -------------------------------------------------------------------------

    mov edi, PD_ADDR
    mov eax, APIC_BASE | PT_PRESENT | PT_WRITABLE | PT_PAGE_SIZE_2M | PT_CACHE_DISABLE
    mov [edi + 503 * 8], eax


    ; -------------------------------------------------------------------------
    ; PT[0..511]
    ; -------------------------------------------------------------------------

    mov edi, PT_ADDR

    xor ebx, ebx

    mov eax, PT_PRESENT | PT_WRITABLE
    mov ecx, PT_ENTRIES

.map_page:

    mov [edi], eax

    add eax, PAGE_SIZE
    add edi, 8

    loop .map_page


    ; -------------------------------------------------------------------------
    ; CR3 = adres PML4
    ; -------------------------------------------------------------------------

    mov eax, PML4_ADDR
    mov cr3, eax

    ret


; =============================================================================
; PROTECTED MODE -> LONG MODE
; =============================================================================

enter_long_mode:

    ; -------------------------------------------------------------------------
    ; Włącz PAE.
    ; -------------------------------------------------------------------------

    mov eax, cr4
    or eax, CR4_PAE
    mov cr4, eax


    ; -------------------------------------------------------------------------
    ; Włącz EFER.LME.
    ; -------------------------------------------------------------------------

    mov ecx, EFER_MSR
    rdmsr

    or eax, EFER_LME

    wrmsr


    ; -------------------------------------------------------------------------
    ; Włącz paging.
    ;
    ; PAE + LME + PG = procesor przechodzi do long mode po far jumpie.
    ; -------------------------------------------------------------------------

    mov eax, cr0
    or eax, CR0_PG
    mov cr0, eax


    ; -------------------------------------------------------------------------
    ; Załaduj GDT zawierającą 64-bitowy code descriptor.
    ; -------------------------------------------------------------------------

    lgdt [gdtr64]

    ; Far jump ustawia CS na deskryptor z L=1.
    jmp CODE64_SEL:long_mode


; =============================================================================
; LONG MODE
; =============================================================================

[BITS 64]

long_mode:

    ; Tymczasowy segment danych bootloadera.
    ; Kernel później załaduje własną GDT.
    mov ax, DATA64_SEL

    mov ds, ax
    mov es, ax
    mov ss, ax


    ; Przygotuj kernelowy stos.
    mov rsp, 0x90000
    mov byte [0xB8502], 'C'
    mov byte [0xB8503], 0x07


    ; -------------------------------------------------------------------------
    ; Kernel/entry został załadowany wcześniej pod 0x8000.
    ; -------------------------------------------------------------------------

    mov rax, KERNEL_LOAD_ADDR
    jmp rax


; =============================================================================
; TEMPORARY GDT
;
; Tylko do przejścia do protected/long mode.
;
; Kernel ma własną GDT i załaduje ją później.
; =============================================================================

[BITS 16]

gdt32:

    dq 0x0000000000000000           ; 0x00 null
    dq 0x00CF9A000000FFFF           ; 0x08 32-bit code
    dq 0x00CF92000000FFFF           ; 0x10 32-bit data

gdt32_end:


gdtr32:
    dw gdt32_end - gdt32 - 1
    dd gdt32


; -------------------------------------------------------------------------
; GDT dla long mode.
; -------------------------------------------------------------------------

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


; =============================================================================
; BIOS boot signature
; =============================================================================

times 510 - ($ - $$) db 0
dw 0xAA55
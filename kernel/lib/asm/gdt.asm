[bits 64]

global gdt_load
global gdt_reload_cs
global gdt_reload_data_segments
global tss_load
global enter_user_mode

gdt_load:
    lgdt [rdi]
    ret

gdt_reload_cs:
    push 0x08
    lea rax, [.reload]
    push rax
    retfq

.reload:
    ret


gdt_reload_data_segments:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov fs, ax
    mov gs, ax
    ret


tss_load:
    mov ax, di
    ltr ax
    ret

enter_user_mode:
    ; RDI = user stack
    ; RSI = user RIP

    cli

    mov ax, 0x23
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    push 0x23            ; user SS
    push rdi             ; user RSP

    pushfq
    or qword [rsp], 0x200    ; IF = 1

    push 0x1B            ; user CS
    push rsi             ; user RIP

    iretq
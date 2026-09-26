[BITS 64]

section .text

global idt_load
global isr_0_de
global isr_1_db
global isr_2_nmi
global isr_3_bp
global isr_4_of
global isr_5_br
global isr_6_ud
global isr_7_nm
global isr_8_df
global isr_10_ts
global isr_11_np
global isr_12_ss
global isr_13_gp
global isr_14_pf
global isr_16_mf
global isr_17_ac
global isr_18_mc
global isr_19_xm
global isr_20_ve
global isr_21_cp
global isr_reserved
global isr_32_irq0

extern exception_handler

%macro SAVE_REGISTERS 0
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push rbp
    push r8
    push r9
    push r10
    push r11
    push r12
    push r13
    push r14
    push r15
%endmacro

%macro RESTORE_REGISTERS 0
    pop r15
    pop r14
    pop r13
    pop r12
    pop r11
    pop rbp
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
%endmacro

%macro ISR_NO_ERROR 2
%1:
    SAVE_REGISTERS

    ; R12 = początek zapisanych rejestrów
    mov r12, rsp

    ; R13 = początek hardware frame
    mov r13, rsp
    add r13, 120

    ; Wyrównanie stosu przed CALL
    and rsp, -16

    ; struct interrupt_frame = 56 bajtów
    sub rsp, 56

    ; vector
    mov qword [rsp + 0], %2

    ; brak error code
    mov qword [rsp + 8], 0

    ; RIP
    mov rax, [r13 + 0]
    mov [rsp + 16], rax

    ; CS
    mov rax, [r13 + 8]
    mov [rsp + 24], rax

    ; RFLAGS
    mov rax, [r13 + 16]
    mov [rsp + 32], rax

    ; Domyślnie brak RSP/SS
    mov qword [rsp + 40], 0
    mov qword [rsp + 48], 0

    ; Czy przerwanie przyszło z ring 3?
    test byte [rsp + 24], 3
    jz %%from_ring0

    ; RSP
    mov rax, [r13 + 24]
    mov [rsp + 40], rax

    ; SS
    mov rax, [r13 + 32]
    mov [rsp + 48], rax

%%from_ring0:
    lea rdi, [rsp]
    call exception_handler

    ; Przywracamy stos sprzed alignowania
    mov rsp, r12

    RESTORE_REGISTERS

    iretq
%endmacro

%macro ISR_ERROR 2
%1:
    SAVE_REGISTERS

    mov r12, rsp

    ; Początek hardware frame
    mov r13, rsp
    add r13, 120

    and rsp, -16
    sub rsp, 56

    ; vector
    mov qword [rsp + 0], %2

    ; error code
    mov rax, [r13 + 0]
    mov [rsp + 8], rax

    ; RIP
    mov rax, [r13 + 8]
    mov [rsp + 16], rax

    ; CS
    mov rax, [r13 + 16]
    mov [rsp + 24], rax

    ; RFLAGS
    mov rax, [r13 + 24]
    mov [rsp + 32], rax

    mov qword [rsp + 40], 0
    mov qword [rsp + 48], 0

    ; Czy nastąpiła zmiana CPL?
    test byte [rsp + 24], 3
    jz %%from_ring0

    ; RSP
    mov rax, [r13 + 32]
    mov [rsp + 40], rax

    ; SS
    mov rax, [r13 + 40]
    mov [rsp + 48], rax

%%from_ring0:
    lea rdi, [rsp]
    call exception_handler

    mov rsp, r12

    RESTORE_REGISTERS

    ; CPU samo usunie error code
    iretq
%endmacro

ISR_NO_ERROR isr_0_de,  0
ISR_NO_ERROR isr_1_db,  1
ISR_NO_ERROR isr_2_nmi, 2
ISR_NO_ERROR isr_3_bp,  3
ISR_NO_ERROR isr_4_of,  4
ISR_NO_ERROR isr_5_br,  5
ISR_NO_ERROR isr_6_ud,  6
ISR_NO_ERROR isr_7_nm,  7

ISR_ERROR    isr_8_df,  8

ISR_ERROR    isr_10_ts, 10
ISR_ERROR    isr_11_np, 11
ISR_ERROR    isr_12_ss, 12
ISR_ERROR    isr_13_gp, 13
ISR_ERROR    isr_14_pf, 14

ISR_NO_ERROR isr_16_mf, 16
ISR_ERROR    isr_17_ac, 17
ISR_NO_ERROR isr_18_mc, 18
ISR_NO_ERROR isr_19_xm, 19
ISR_NO_ERROR isr_20_ve, 20
ISR_ERROR    isr_21_cp, 21

idt_load:
    lidt [rdi]
    ret

isr_32_irq0:
    iretq

isr_reserved:
    cli

.hang:
    hlt
    jmp .hang
[BITS 64]

section .text

global apic_cpuid
global apic_rdmsr
global apic_wrmsr


; =============================================================================
; CPUID
;
; uint32_t apic_cpuid(uint32_t leaf)
;
; RDI = leaf
;
; Zwracamy EAX.
; =============================================================================

apic_cpuid:
    mov eax, edi
    cpuid
    ret


; =============================================================================
; RDMSR
;
; uint64_t apic_rdmsr(uint32_t msr)
;
; RDI = numer MSR
;
; EDX:EAX -> wynik 64-bitowy
; =============================================================================

apic_rdmsr:
    mov ecx, edi
    rdmsr

    shl rdx, 32
    or rax, rdx

    ret


; =============================================================================
; WRMSR
;
; void apic_wrmsr(uint32_t msr, uint64_t value)
;
; RDI = numer MSR
; RSI = wartość
; =============================================================================

apic_wrmsr:
    mov ecx, edi

    mov rax, rsi
    mov rdx, rsi
    shr rdx, 32

    wrmsr

    ret
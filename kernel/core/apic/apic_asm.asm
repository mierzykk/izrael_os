[BITS 64]

section .text

global apic_cpuid
global apic_rdmsr
global apic_wrmsr


; void apic_cpuid(uint32_t leaf, struct cpuid_result *result)
; RDI = leaf
; RSI = result

apic_cpuid:
    mov eax, edi
    xor ecx, ecx
    cpuid

    mov [rsi + 0], eax
    mov [rsi + 4], ebx
    mov [rsi + 8], ecx
    mov [rsi + 12], edx
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
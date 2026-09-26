[BITS 64]

global entry
extern maink

section .text.entry

entry:
    ;kolejny zaawansowany debug
    mov byte [0xB8500], 'D'
    mov byte [0xB8501], 0x07

    call maink

.done:
    hlt
    jmp .done

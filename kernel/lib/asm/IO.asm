[bits 64]

global outb
global inb

;void outb(uint16_t port, uint8_t value)
;EDI = port (16-bit -> DX)
;ESI = value (8-bit -> AL)
outb:
    mov dx, di      ; Przeniesienie portu do DX
    mov al, sil     ; Przeniesienie wartoci do AL
    out dx, al      ; Wysylanie bajtu AL na port DX
    ret

;uint8_t inb(uint16_t port)
;EDI = port (16-bit -> DX)
;Zwracana wartość (uint8_t) -> AL
inb:
    mov dx, di      ; Przeniesienie portu do DX
    in al, dx       ; Odczyt bajtu z portu DX do AL
    ret

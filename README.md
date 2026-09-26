# izrael os

jakby ktos dlaczego podzial plikow jak taki dziwny to dlatego ze skopiowalem strukture plikow z neta i robilem po swojemu makefile jest vibecoded nie chce mi sie bawic w nauke robienia makefile tak samo jak linker.ld boot.asm napisalem ja ale ai potem przepisalo bo czesto bledami sypalo

## co jest zrobione?
- bootloader 64 bit
- I/O (tylko inb i outb)
- serial
- gdt
- idt
- apic

projekt byl sprawdzany na wsl

## sprawdzanie narzedzi
```bash
make test
```

## uruchomienie os
```bash
make run
```

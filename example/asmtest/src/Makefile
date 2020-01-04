RISCV_TARGET=~/temp/riscv-gnu-toolchain/build/bin/riscv64-unknown-linux-gnu-


CFLAGS=-mcmodel=medany -nostdlib -nostartfiles -march=rv32im -mabi=ilp32 -mstrict-align -static -fvisibility=hidden
LDFLAGS=-march=rv32im -nostdlib -nostartfiles -Wl,-T./bare-link.ld
OBJDUMPFLAGS=-s -d -Mno-aliases -Mnumeric


all:
	mkdir -p obj
	$(RISCV_TARGET)gcc $(CFLAGS) $(LDFLAGS) ./entry.s ../assembly.s  -o ./obj/binary.elf
	$(RISCV_TARGET)objdump $(OBJDUMPFLAGS) ./obj/binary.elf
	cd obj; bash ../strip.sh

max:
	mkdir -p obj
	$(RISCV_TARGET)gcc $(CFLAGS) $(LDFLAGS) ./entry_max.s ../assembly.s  -o ./obj/binary.elf
	$(RISCV_TARGET)objdump $(OBJDUMPFLAGS) ./obj/binary.elf
	cd obj; bash ../strip.sh

gcd:
	mkdir -p obj
	$(RISCV_TARGET)gcc $(CFLAGS) $(LDFLAGS) ./entry_gcd.s ../assembly.s  -o ./obj/binary.elf
	$(RISCV_TARGET)objdump $(OBJDUMPFLAGS) ./obj/binary.elf
	cd obj; bash ../strip.sh

sort:
	mkdir -p obj
	$(RISCV_TARGET)gcc $(CFLAGS) $(LDFLAGS) ./entry_sort.s ../assembly.s  -o ./obj/binary.elf
	$(RISCV_TARGET)objdump $(OBJDUMPFLAGS) ./obj/binary.elf
	cd obj; bash ../strip.sh

RISCV_TARGET=~/temp/riscv-gnu-toolchain/build/bin/riscv64-unknown-linux-gnu-


CFLAGS=-mcmodel=medany -nostdlib -nostartfiles -march=rv32im -mabi=ilp32 -mstrict-align -static -fvisibility=hidden
LDFLAGS=-march=rv32im -nostdlib -nostartfiles -Wl,-T./bare-link.ld
OBJDUMPFLAGS=-d -Mno-aliases -Mnumeric


max: entry_max.s ../assembly.s ./support.s
	mkdir -p obj
	$(RISCV_TARGET)gcc $(CFLAGS) $(LDFLAGS) ./entry_max.s ../assembly.s ./support.s  -o ./obj/binary.elf
	$(RISCV_TARGET)objdump $(OBJDUMPFLAGS) ./obj/binary.elf
	cd obj; bash ../strip.sh

gcd: entry_sort.s ../assembly.s ./support.s
	mkdir -p obj
	$(RISCV_TARGET)gcc $(CFLAGS) $(LDFLAGS) ./entry_gcd.s ../assembly.s  ./support.s -o ./obj/binary.elf
	$(RISCV_TARGET)objdump $(OBJDUMPFLAGS) ./obj/binary.elf
	cd obj; bash ../strip.sh

sort: entry_sort.s ../assembly.s ./support.s
	mkdir -p obj
	$(RISCV_TARGET)gcc $(CFLAGS) $(LDFLAGS) ./entry_sort.s ../assembly.s ./support.s  -o ./obj/binary.elf
	$(RISCV_TARGET)objdump $(OBJDUMPFLAGS) ./obj/binary.elf
	cd obj; bash ../strip.sh

RISCV_TARGET=~/temp/riscv-gnu-toolchain/build/bin/riscv64-unknown-linux-gnu-


CFLAGS=-mcmodel=medany -nostdlib -nostartfiles -march=rv32i -mabi=ilp32 -mstrict-align -static -fvisibility=hidden
LDFLAGS=-march=rv32i -nostdlib -nostartfiles -Wl,-T./bare-link.ld
OBJDUMPFLAGS=-s -d -Mno-aliases -Mnumeric


all:
	mkdir -p obj
	$(RISCV_TARGET)gcc $(CFLAGS) $(LDFLAGS) ../assembly.s  -o ./obj/binary.elf
	echo ""
	$(RISCV_TARGET)objdump $(OBJDUMPFLAGS) ./obj/binary.elf
	echo ""
	cd obj; bash ../strip.sh

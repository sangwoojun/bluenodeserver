RISCV_TARGET=~/temp/riscv-gnu-toolchain/build/bin/riscv64-unknown-linux-gnu-


CFLAGS=-mcmodel=medany -nostdlib -nostartfiles -march=rv32i -mabi=ilp32 -mstrict-align -static -fvisibility=hidden
LDFLAGS=-march=rv32i -nostdlib -nostartfiles -Wl,-T../bare-link.ld


all:
	mkdir -p obj
	$(RISCV_TARGET)gcc $(CFLAGS) $(LDFLAGS) mnist.s  -o ./obj/binary.elf
	cd obj; bash ../../strip.sh

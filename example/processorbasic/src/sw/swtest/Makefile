RISCV_TARGET=~/temp/riscv-gnu-toolchain/build/bin/riscv64-unknown-linux-gnu-


CFLAGS=-mcmodel=medany -nostdlib -nostartfiles -march=rv32i -mabi=ilp32 -mstrict-align -static -fvisibility=hidden
LDFLAGS=-march=rv32i -nostdlib -nostartfiles -Wl,-T../tools/bare-link.ld


all:
	$(RISCV_TARGET)gcc $(CFLAGS) $(LDFLAGS) gcd_sw.S  -o gcd_sw
	$(RISCV_TARGET)gcc $(CFLAGS) $(LDFLAGS) entry.s test.c  -o test
	bash strip.sh

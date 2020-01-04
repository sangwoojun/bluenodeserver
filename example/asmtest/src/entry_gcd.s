.text
start:
	li sp, 0x10000
	li t0, 0x2000
	lw a0, 0(t0)
	lw a1, 4(t0)
	jal gcd
	.word 0

.global output
output:
	li t0, 0x3000
	sw a0, 0(t0)
	ret

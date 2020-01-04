.text
start:
	li sp, 0x10000
	li a0, 0x2000
	li a1, 32
	jal max
	.word 0

.global output
output:
	li t0, 0x3000
	sw a0, 0(t0)
	ret

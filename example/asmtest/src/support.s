.global output
output:
	li t0, 0x3000
	sw a0, 0(t0)
	ret

.global footer
footer:
	li t0, 0x3000
	sw a0, 4(t0)
	sw a1, 8(t0)
	.word 0

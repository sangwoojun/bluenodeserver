.global output
output:
	li t0, 0x3000
	add t1, a0, 0
	li t2, 0
	li t3, 0
	li t4, 0
	li t5, 0
	li t6, 0
	sw t1, 0(t0)
	ret

.global footer
footer:
	li t0, 0x3000
	sw a0, 4(t0)
	sw a1, 8(t0)
	sw a2, 4(t0)
	sw a3, 8(t0)
	.word 0

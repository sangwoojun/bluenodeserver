.text
start:
	li sp, 0x10000
	li t0, 0x2000
	lw a0, 0(t0)
	lw a1, 4(t0)

	lw s0, 0(a0)
	lw s1, 4(a0)
	lw s2, 0(a0)
	lw s3, 4(a0)


	jal gcd
	
	add a0, s0, 0
	add a1, s1, 0
	add a2, s2, 0
	add a3, s3, 0
	jal footer

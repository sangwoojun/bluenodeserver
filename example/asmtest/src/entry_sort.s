.text
start:
	li sp, 0x10000
	lw a0, 0x2000
	li a1, 8
	lw s0, 0(a0)
	lw s1, 4(a0)

	jal sort
	
	add a0, s0, 0
	add a1, s1, 0
	jal footer

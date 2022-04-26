/*
	Combines fib_rec which computes nth fibonacci number recursively
    and the original rv32_mult assembly routines to test SMT.
*/
	data = 0x400
	stack = 0x1000
    li  x8, 1
	li	x31, stack
	
	li	x17, 14
	jal	x27,	fib #

	li	x2, data
	sw	x1, 0(x2)	
	wfi
	
fib:	beq	x17,	x0,	fib_ret_1 # arg is 0: return 1

	#cmpeq	x2,	x17,	1 # arg is 1: return 1
	beq	x17,	x8,	fib_ret_1 #

	addi	x31,	x31,	-32 # allocate stack frame
	sw	x27, 24(x31)	

	sw	x17, 0(x31)	

	addi	x17,	x17,	-1 # arg = arg-1
	jal	x27,	fib # call fib
	sw	x1, 8(x31)	

	lw	x17, 0(x31)	
	addi	x17,	x17,	-2 # arg = arg-2
	jal	x27,	fib # call fib

	lw	x2, 8(x31)	
	add	x1,	x2,	x1 # fib(arg-1)+fib(arg-2)

	lw	x27, 24(x31)	
	addi	x31,	x31,	32 # deallocate stack frame
	jalr x0, x27, 0
fib_ret_1:
	li	x1,	1 # set return value to 1
	jalr x0, x27, 0
    nop
    nop
	nop
    nop
	nop
	nop
    nop
    nop
    nop
	nop
    nop
	nop
	nop
    nop
    nop
    nop
	nop
    nop
	nop
	nop
    nop
    nop
    nop
	nop
    nop
	nop
	nop
    nop
    nop
    nop
	nop
    nop
	nop
	nop
    nop
    nop
	nop
	nop
    nop # Offset thread 1's address to be 0x100
        data1 = 0x1008
	li	x1, data1       # Needs to be partitioned from rv32_rec.s
	jal	x2,	start #
	.dword 2862933555777941757
	.dword 	3037000493
start:	lw	x3, 0(x2) # Points to .dword 2862933555777941757 here
	lw	x4, 8(x2) 	  # Points to .dword 3037000493
	li	x5, 0			
loop:	addi	x5,	x5,	1 #
	slti	x6,	x5,	16 #
	mul	x11,	x2,	x3 #
	add	x11,	x11,	x4 #
	mul	x12,	x11,	x3 #
	add	x12,	x12,	x4 #
	mul	x13,	x12,	x3 #
	add	x13,	x13,	x4 #
	mul	x2,	x13,	x3 #
	add	x2,	x2,	x4 #
	srli	x11,	x11,	0 #
	sw	x11, 0(x1)
	srli	x12,	x12,	0 #
	sw	x12, 8(x1)
	srli	x13,	x13,	0 #
	sw	x13, 16(x1)
	srli	x14,	x2,	0 #
	sw	x14, 24(x1)
	addi	x1,	x1,	32 #
	bne	x6,	x0,	loop #
	wfi

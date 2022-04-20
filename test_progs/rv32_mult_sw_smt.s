/*
  This test was hand written by Joel VanLaven to put pressure on ROBs
  It generates and stores in order 64 32-bit pseudo-random numbers in 
  16 passes using 64-bit arithmetic.  (i.e. it actually generates 64-bit
  values and only keeps the more random high-order 32 bits).  The constants
  are from Knuth.  To be effective in testing the ROB the mult must take
  a while to execute and the ROB must be "small enough".  Assuming that
  there is any reasonably working form of branch prediction and that the
  Icache works and is large enough, multiple passes should end up going
  into the ROB at the same time increasing the efficacy of the test.  If
  for some reason the ROB is not filling with this test is should be
  easily modifiable to fill the ROB.

  In order to properly pass this test the pseudo-random numbers must be
  the correct numbers.
*/
        data = 0x1000
	li	x1, data
	jal	x2,	start #
	.dword 2862933555777941757
	.dword 	3037000493
start:	lw	x3, 0(x2)
	lw	x4, 8(x2)
	li	x5, 0
loop:	addi	x5,	x5,	1 #
	slti	x6,	x5,	16 #
	lw	 x4,	0(x1)
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
	sw	x12, 16(x1)
	srli	x13,	x13,	0 #
	sw	x13, 32(x1)
	srli	x14,	x2,	0 #
	sw	x14, 48(x1)
	addi	x1,	x1,	32 #
	bne	x6,	x0,	loop #
	wfi
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
        data1 = 0x1000
	li	x1, data1			# Starts at 0x100
	jal	x2,	start1 #
	.dword 2862933555777941757
	.dword 	3037000493
start1:	lw	x3, 0(x2)       # loads  2862933555777941757
	lw	x4, 8(x2)           # loads  3037000493
	li	x5, 0
loop1:	addi	x5,	x5,	1 #
	slti	x6,	x5,	16 # (set 1 (if) less than immediate)
	lw	 x4,	8(x1)
	mul	x11,	x2,	x3 #
	add	x11,	x11,	x4 #
	mul	x12,	x11,	x3 #
	add	x12,	x12,	x4 #
	mul	x13,	x12,	x3 #
	add	x13,	x13,	x4 #
	mul	x2,	x13,	x3 #
	add	x2,	x2,	x4 #
	srli	x11,	x11,	0 # Shift right logical immediate
	sw	x11, 8(x1)
	srli	x12,	x12,	0 #
	sw	x12, 24(x1)
	srli	x13,	x13,	0 #
	sw	x13, 40(x1)
	srli	x14,	x2,	0 #
	sw	x14, 56(x1)
	addi	x1,	x1,	32 #
	bne	x6,	x0,	loop # while ( x5 < 16 ) 
	wfi
	
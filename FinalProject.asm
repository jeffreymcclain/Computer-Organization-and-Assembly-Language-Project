	.data
w:		.asciiz "w"
r:		.asciiz "r"
bigr:		.asciiz "R"
bigw:		.asciiz "W"
rowOne:	.asciiz "row 1: "
columnOne:	.asciiz "column 1: "
rowTwo:	.asciiz "row 2: "
columnTwo:	.asciiz "column 2: "
wrongColor:	.asciiz "error: (r1,c1) either has wrong color or no game piece \n"
impossible: .asciiz "error: illegal move or jump \n"
redWins:	.asciiz "Red wins!"
whiteWins:	.asciiz "White wins!"
userPrompt:	.asciiz "Enter 0 to go first, or 1 to go second: "
nl:		.asciiz "\n"
	.globl main
	.code
	
main:
	addi $sp,$sp,-384		# stores 2D jump array, 24 * 4 * 4 = 384
	mov $t0,$sp
	mov $s6,$sp
setZeroJump:				#initialize 2D jump array to all zeroes
	sw $0,0($t0)			
	addi $t0,$t0,4
	blt $t0,96,setZeroJump
	
	addi $sp,$sp,-384		# stores 2D move array, 24 * 4 * 4 = 384
	mov $t0,$sp
	mov $s7,$sp
setZeroMove:				#initialize 2D move array to all zeroes
	sw $0,0($t0)			
	addi $t0,$t0,4
	blt $t0,96,setZeroMove	
	
	jal board
	la $a0,userPrompt
	syscall $print_string
	syscall $read_int
	mov $s1,$v0
	li $s2,6				# $s2 = redPieceCount
	li $s3,6				# $s3 = whitePieceCount
loop:
	la $a0,nl
	syscall $print_string
	jal displayBoard
	addi $sp,$sp,-20
	beq $s1,0,userTurn
	
getValid:
	mov $a1,$s0			#$a1 = $s0 = board pointer
	mov $a2,$s6			#$a2 is pointer to *tupleList
	li $a3,1
	jal getValidJumps
	beq $v1,$0,noJumps
	j tryAgain
	
noJumps:	
	mov $a1,$s0			#$a1 = $s0 = board pointer
	mov $a2,$s7			#$a2 is pointer to *tupleList
	li $a3,1
	jal getValidMoves
	j movesLFSR
	
tryAgain:
	syscall $random
	mov $a1,$v0						#sets initial LFSR state to the random number
	li $t4,0							# count = 0
	li $t5,0							#set inital LSB to zero 
randomNum:	
	jal LFSR
	or $t5,$t5,$t2						# add new LSB to previous total
	sll $t5,$t5,1						# shift LSB to the left 1, store result in $s1
	addi $t4,$t4,1						#increment count by 1
	blt $t4,4,randomNum					#calls state = LFSR(state) 4 times
	jal LFSR							#calls state one last time, to add the last LSB
	or $t5,$t5,$t2
	rem $t5,$t5,$v1
	mov $a1,$s6
	mov $a2,$t5						#pass random 0-23 LFSR number to printTuples
	j afterRandom
	
movesLFSR:
	syscall $random
	mov $a1,$v0						#sets initial LFSR state to the random number
	li $t4,0							# count = 0
	li $t5,0							#set inital LSB to zero 
randomNumber:	
	jal LFSR
	or $t5,$t5,$t2						# add new LSB to previous total
	sll $t5,$t5,1						# shift LSB to the left 1, store result in $s1
	addi $t4,$t4,1						#increment count by 1
	blt $t4,4,randomNumber					#calls state = LFSR(state) 4 times
	jal LFSR							#calls state one last time, to add the last LSB
	or $t5,$t5,$t2
	rem $t5,$t5,$v1
	mov $a1,$s7
	mov $a2,$t5						#pass random 0-23 LFSR number to printTuples
afterRandom:
	jal passTuples
	j afterComputer
	
userTurn:
	sw $s0,16($sp)
	la $a0,rowOne
	syscall $print_string
	syscall $read_int
	mov $t0,$v0			# $t0 = r1
	sw $v0,12($sp)
	la $a0,columnOne
	syscall $print_string
	syscall $read_int
	mov $t1,$v0			# $t1 = c1
	sw $v0,8($sp)
	la $a0,rowTwo
	syscall $print_string
	syscall $read_int
	sw $v0,4($sp)
	la $a0,columnTwo
	syscall $print_string
	syscall $read_int
	sw $v0,0($sp)
afterComputer:	
	lw $t0,12($sp)
	lw $t1,8($sp)
	sub $t0,$0,$t0
	addi $t0,$t0,5
	mul $t0,$t0,6
	add $t1,$t0,$t1
	mul $t1,$t1,4			# ((5-row)*6 + column) * 4 = $t1
	add $t1,$s0,$t1		# add $s0 board pointer to coordinate to find array offset
	lw $s4,0($t1)			# $s4 = the value of the game piece at (r1,c1)
	
	sub $t3,$s4,1			# 1 - 1 = 0  (checks if red)
	beq $t3,$s1,currentColor
	sub $t3,$s4,5			# 5 - 5 = 0  (checks if red king)
	beq $t3,$s1,currentColor
	sub $t3,$s4,2			# 3 - 2 = 1  (checks if white)
	beq $t3,$s1,currentColor
	sub $t3,$s4,6			# 7 - 6 = 1  (checks if white king)
	beq $t3,$s1,currentColor
	la $a0,wrongColor
	syscall $print_string
	addi $sp,$sp,20
	j loop
	
currentColor:
	jal isValidJump
	beq $v1,1,jump
	jal isValidMove
	beq $v1,1,moveGamePiece
	la $a0,impossible
	syscall $print_string
	addi $sp,$sp,20
	j loop
	
jump:
	lw $t0,12($sp)		# $t0 = r1
	lw $t1,8($sp)			# $t1 = c1
	lw $t2,4($sp)			# $t2 = r2
	lw $t3,0($sp)			# $t3 = c2
	sub $t4,$0,$t2
	addi $t4,$t4,5
	mul $t4,$t4,6
	add $t4,$t4,$t3
	mul $t4,$t4,4			# ((5-row)*6 + column) * 4 = $t4
	add $t4,$s0,$t4		# add $s0 board pointer to coordinate to find array offset
	sw $s4,0($t4)			# moving value ($s4) of game piece at coord (r1,c1) to new coord (r2,c2)
	
	sub $t4,$0,$t0
	addi $t4,$t4,5
	mul $t4,$t4,6
	add $t4,$t4,$t1
	mul $t4,$t4,4			# ((5-row)*6 + column) * 4 = $t4
	add $t4,$s0,$t4		# add $s0 board pointer to coordinate to find array offset
	sw $0,0($t4)			# delete game piece from (r1,c1)
	
	add $t4,$t0,$t2		
	div $t4,$t4,2			# $t4 = rm
	add $t5,$t1,$t3
	div $t5,$t5,2			# $t5 = cm
	
	sub $t4,$0,$t4
	addi $t4,$t4,5
	mul $t4,$t4,6
	add $t5,$t4,$t5
	mul $t5,$t5,4			# ((5-row)*6 + column) * 4 = $t5
	add $t5,$s0,$t5		# add $s0 board pointer to coordinate to find array offset
	sw $0,0($t5)			# delete game piece from (rm,cm)
	
	beq $s1,0,decrementWhite	#if $s1 = 0, then color = red, so the red piece removes the white piece
decrementRed:
	addi $s2,$s2,-1
	j kingMeCheckJump
decrementWhite:
	addi $s3,$s3,-1

kingMeCheckJump:
	beq $s1,0,kingMeCheckRedJump
	beq $s1,1,kingMeCheckWhiteJump
	j exitCheck
	
kingMeCheckRedJump:
	beq $t2,5,kingMeRedJump
	j exitCheck
kingMeCheckWhiteJump:
	beq $t2,0,kingMeWhiteJump
	j exitCheck

kingMeRedJump:
	sub $t4,$0,$t2			# $t2 = r2
	addi $t4,$t4,5			
	mul $t4,$t4,6
	add $t4,$t4,$t3		# $t3 = c2
	mul $t4,$t4,4			
	add $t4,$s0,$t4		
	li $t5,5				# $t5 = 5 = red king
	sw $t5,0($t4)			# convert (r2,c2) to a red king
	j exitCheck
	
kingMeWhiteJump:
	sub $t4,$0,$t2			# $t2 = r2
	addi $t4,$t4,5
	mul $t4,$t4,6
	add $t4,$t4,$t3		# $t3 = c2
	mul $t4,$t4,4			
	add $t4,$s0,$t4		
	li $t5,7				# $t5 = 7 = white king
	sw $t5,0($t4)			# convert (r2,c2) to a white king
	j exitCheck
	
moveGamePiece:
	lw $t0,12($sp)		# $t0 = r1
	lw $t1,8($sp)			# $t1 = c1
	lw $t2,4($sp)			# $t2 = r2
	lw $t3,0($sp)			# $t3 = c2
	sub $t4,$0,$t2
	addi $t4,$t4,5
	mul $t4,$t4,6
	add $t4,$t4,$t3
	mul $t4,$t4,4			# ((5-row)*6 + column) * 4 = $t4
	add $t4,$s0,$t4		# add $s0 board pointer to coordinate to find array offset
	sw $s4,0($t4)			# moving value ($s4) of game piece at coord (r1,c1) to new coord (r2,c2)
	
	sub $t4,$0,$t0
	addi $t4,$t4,5
	mul $t4,$t4,6
	add $t4,$t4,$t1
	mul $t4,$t4,4			# ((5-row)*6 + column) * 4 = $t4
	add $t4,$s0,$t4		# add $s0 board pointer to coordinate to find array offset
	sw $0,0($t4)			# delete game piece from (r1,c1)

	beq $s1,0,kingMeCheckRedMove
kingMeCheckWhiteMove:
	beq $t2,0,kingMeWhiteMove
	j changeColor
kingMeCheckRedMove:
	beq $t2,5,kingMeRedMove
	j changeColor

kingMeRedMove:
	sub $t4,$0,$t2			# $t2 = r2
	addi $t4,$t4,5			
	mul $t4,$t4,6
	add $t4,$t4,$t3		# $t3 = c2
	mul $t4,$t4,4			
	add $t4,$s0,$t4		
	li $t5,5				# $t5 = 5 = red king
	sw $t5,0($t4)			# convert (r2,c2) to a red king
	j changeColor
	
kingMeWhiteMove:
	sub $t4,$0,$t2			# $t2 = r2
	addi $t4,$t4,5
	mul $t4,$t4,6
	add $t4,$t4,$t3		# $t3 = c2
	mul $t4,$t4,4			
	add $t4,$s0,$t4		
	li $t5,7				# $t5 = 7 = white king
	sw $t5,0($t4)			# convert (r2,c2) to a white king
	j changeColor

exitCheck:
	beq $s2,0,winnerWhite
	beq $s3,0,winnerRed
	j changeColor	
	
changeColor:
	addi $sp,$sp,20
	beq $s1,0,whitesTurn
	j redsTurn
whitesTurn:
	li $s1,1
	j loop
redsTurn:
	li $s1,0
	j loop
	
winnerRed:
	la $a0,redWins
	syscall $print_string
	j exit
winnerWhite:
	la $a0,whiteWins
	syscall $print_string
exit:
	syscall $exit


LFSR:									# state = (state >> 1) ^ (-(state & 0x00000001) & taps)
	li $t0,0xCA000						# taps = x^20 + x^19 + x^16 + x^14 + 1 = 1100 1010 0000 0000 0000 = 0xCA000					
	srl $t1,$a1,1						
	andi $t2,$a1,0x00000001				# $t2 = LSB = state & 0x00000001
	neg $t3,$t2						
	and $t3,$t3,$t0					
	xor $a1,$t1,$t3					
	jr $ra
	
passTuples:
	sw $s0,16($sp)
	mul $t1,$a2,16
	add $t1,$a1,$t1
	lw $t2,0($t1)
	sw $t2,12($sp)
	
	mul $t1,$a2,4				# (row * 4 + column) * 4 = $t1
	addi $t1,$t1,1
	mul $t1,$t1,4
	add $t1,$a1,$t1
	lw $t3,0($t1)
	sw $t3,8($sp)
	
	mul $t1,$a2,4
	addi $t1,$t1,2
	mul $t1,$t1,4
	add $t1,$a1,$t1
	lw $t4,0($t1)
	add $t2,$t2,$t4			# add the offset for r2 and c2
	sw $t2,4($sp)
	
	mul $t1,$a2,4
	addi $t1,$t1,3
	mul $t1,$t1,4
	add $t1,$a1,$t1
	lw $t4,0($t1)
	add $t3,$t3,$t4
	sw $t3,0($sp)
	jr $ra

getValidJumps:				# (int *board, int *tupleList, int color)
	addi $sp,$sp,-8
	sw $a3,4($sp)
	sw $ra,0($sp)	
	li $t0,0				# $t0 = total
	li $t1,0				# $t1 = r1
	j tuplesJumpTest1
tuplesJumpLoop1:
	li $t2,0				# $t2 = c1
	j tuplesJumpTest2
tuplesJumpLoop2:
	li $t3,-2				# $t3 = r2
	j tuplesJumpTest3
tuplesJumpLoop3:
	li $t4,-2				# $t4 = c2
	j tuplesJumpTest4
tuplesJumpLoop4:
	addi $sp,$sp,-40		#allocate space for the 5 arguments for isValidMove, and the 5 temporary variables
	sw $t0,36($sp)
	sw $t1,32($sp)
	sw $t2,28($sp)
	sw $t3,24($sp)
	sw $t4,20($sp)
	
	sw $s0,16($sp)		#16 + 384 ???????????
	sw $t1,12($sp)
	sw $t2,8($sp)
	add $t5,$t1,$t3		#add row1 + row2 offset together to pass to isValidMove 
	sw $t5,4($sp)
	add $t5,$t2,$t4
	sw $t5,0($sp)			#use $s0 instead of $sp, since $s0 refers to board pointer
	
	sub $t4,$0,$t1
	addi $t4,$t4,5
	mul $t4,$t4,6
	add $t5,$t4,$t2
	mul $t5,$t5,4				# ((5-row)*6 + column) * 4 = $t1
	add $t4,$s0,$t5
	lw $t4,0($t4)				# $t4 = the stack offset to store the value
	
	sub $t5,$t4,1				#1-1= 0
	beq $t5,$a3,checkJumpColor
	sub $t5,$t4,5				#5-5=0
	beq $t5,$a3,checkJumpColor
	
	sub $t5,$t4,2				#3 - 2 =1
	beq $t5,$a3,checkJumpColor
	sub $t5,$t4,6				#7 - 6 = 1
	beq $t5,$a3,checkJumpColor
	j tuplesJumpNext

checkJumpColor:	
	jal isValidJump
	# addi $sp,$sp,20		#deallocate space for the 5 arguments for isValidMove
	mov $a2,$s6		# move pointer to validJumps array to $a2
	lw $t0,36($sp)
	lw $t1,32($sp)
	lw $t2,28($sp)
	lw $t3,24($sp)
	lw $t4,20($sp)
	beq $v1,1,tuplesJumpStorage
	j tuplesJumpNext
	
tuplesJumpStorage:					# (total)*4 + column) * 4 = $a1
	mul $t5,$t0,16
	add $t5,$a2,$t5
	sw $t1,0($t5)
	
	mul $t5,$t0,4
	addi $t5,$t5,1
	mul $t5,$t5,4
	add $t5,$a2,$t5
	sw $t2,0($t5)
	
	mul $t5,$t0,4
	addi $t5,$t5,2
	mul $t5,$t5,4
	add $t5,$a2,$t5
	sw $t3,0($t5)
	
	mul $t5,$t0,4
	addi $t5,$t5,3
	mul $t5,$t5,4
	add $t5,$a2,$t5
	sw $t4,0($t5)
	
	
	addi $t0,$t0,1
	beq $t0,24,tuplesJumpEnd
	
tuplesJumpNext:
	addi $sp,$sp,40		#deallocate space for the 10 arguments for isValidMove
	lw $a3,4($sp)
	addi $t4,$t4,4
tuplesJumpTest4:
	ble $t4,2,tuplesJumpLoop4
	addi $t3,$t3,4
tuplesJumpTest3:
	ble $t3,2,tuplesJumpLoop3
	addi $t2,$t2,1
tuplesJumpTest2:
	blt $t2,6,tuplesJumpLoop2
	addi $t1,$t1,1
tuplesJumpTest1:
	blt $t1,6,tuplesJumpLoop1
tuplesJumpEnd:
	lw $ra,0($sp)
	addi $sp,$sp,8
	mov $v1,$t0
	jr $ra

	
	
	
	
	
getValidMoves:				# (int *board, int *tupleList, int color)
	addi $sp,$sp,-8
	sw $a3,4($sp)			#store color=0 in 4($sp)
	sw $ra,0($sp)			#$s0 stores board pointer, $s1 is already in use by other functions, $s2 stores tuplesPointer
	li $t0,0				# $t0 = total
	li $t1,0				# $t1 = r1
	j tuplesTest1
tuplesLoop1:
	li $t2,0				# $t2 = c1
	j tuplesTest2
tuplesLoop2:
	li $t3,-1				# $t3 = r2
	j tuplesTest3
tuplesLoop3:
	li $t4,-1				# $t4 = c2
	j tuplesTest4
tuplesLoop4:
	addi $sp,$sp,-40		#allocate space for the 5 arguments for isValidMove, and the 5 temporary variables
	sw $t0,36($sp)
	sw $t1,32($sp)
	sw $t2,28($sp)
	sw $t3,24($sp)
	sw $t4,20($sp)
	
	sw $s0,16($sp)		#16 + 384 ???????????
	sw $t1,12($sp)
	sw $t2,8($sp)
	add $t5,$t1,$t3		#add row1 + row2 offset together to pass to isValidMove 
	sw $t5,4($sp)
	add $t5,$t2,$t4
	sw $t5,0($sp)			#use $s0 instead of $sp, since $s0 refers to board pointer
	
	sub $t4,$0,$t1
	addi $t4,$t4,5
	mul $t4,$t4,6
	add $t5,$t4,$t2
	mul $t5,$t5,4				# ((5-row)*6 + column) * 4 = $t1
	add $t4,$s0,$t5
	lw $t4,0($t4)				# $t4 = the stack offset to store the value
	
	sub $t5,$t4,1				#1-1= 0
	beq $t5,$a3,checkColor
	sub $t5,$t4,5				#5-5=0
	beq $t5,$a3,checkColor
	
	sub $t5,$t4,2				#3 - 2 =1
	beq $t5,$a3,checkColor
	sub $t5,$t4,6				#7 - 6 = 1
	beq $t5,$a3,checkColor
	j tuplesNext

checkColor:	
	jal isValidMove
	mov $a2,$s7				# move pointer to tupleList to $a2
	lw $t0,36($sp)
	lw $t1,32($sp)
	lw $t2,28($sp)
	lw $t3,24($sp)
	lw $t4,20($sp)
	beq $v1,1,tuplesStorage
	j tuplesNext
	
tuplesStorage:					# (total)*4 + column) * 4 = $a1
	mul $t5,$t0,16
	add $t5,$a2,$t5
	sw $t1,0($t5)
	
	mul $t5,$t0,4
	addi $t5,$t5,1
	mul $t5,$t5,4
	add $t5,$a2,$t5
	sw $t2,0($t5)
	
	mul $t5,$t0,4
	addi $t5,$t5,2
	mul $t5,$t5,4
	add $t5,$a2,$t5
	sw $t3,0($t5)
	
	mul $t5,$t0,4
	addi $t5,$t5,3
	mul $t5,$t5,4
	add $t5,$a2,$t5
	sw $t4,0($t5)
	
	
	addi $t0,$t0,1
	beq $t0,24,tuplesEnd
	
tuplesNext:
	addi $sp,$sp,40		#deallocate space for the 10 arguments for isValidMove
	lw $a3,4($sp)
	addi $t4,$t4,2
tuplesTest4:
	ble $t4,1,tuplesLoop4
	addi $t3,$t3,2
tuplesTest3:
	ble $t3,1,tuplesLoop3
	addi $t2,$t2,1
tuplesTest2:
	blt $t2,6,tuplesLoop2
	addi $t1,$t1,1
tuplesTest1:
	blt $t1,6,tuplesLoop1
tuplesEnd:
	lw $ra,0($sp)
	addi $sp,$sp,8
	mov $v1,$t0
	jr $ra
	
isValidJump:
	lw $s0,16($sp)		# load pointer to checkerBoard in $s0
	lw $t1,12($sp)		# load the 2 pairs of coordinates in $t0 to $t3
	lw $t2,8($sp)
	lw $t3,4($sp)
	lw $t4,0($sp)			
	
	mov $a1,$t1			#check each pair of coords for validity
	mov $a2,$t2
	addi $sp,$sp,-4
	sw $ra,0($sp)
	jal isLegalPosition
	beq $v1,0,badJump
	
	mov $a1,$t3
	mov $a2,$t4
	jal isLegalPosition
	beq $v1,0,badJump
	
	sub $t5,$0,$t1
	addi $t5,$t5,5
	mul $t5,$t5,6
	add $t5,$t5,$t2
	mul $t5,$t5,4				# ((5-row)*6 + column) * 4 = $t5
	add $t5,$s0,$t5
	lw $t5,0($t5)				# $t4 = the stack offset to store the value
	
	li $v1,1
	beq $t5,1,redJump
	beq $t5,3,whiteJump
	beq $t5,5,redKingJump
	beq $t5,7,whiteKingJump
	j badJump
	
redJump:
	sub $t5,$t1,$t3
	bne $t5,-2,badJump			# (r1-r2)==-2)
	sub $t5,$t2,$t4
	abs $t5,$t5
	bne $t5,2,badJump			# abs(c1-c2)==2
	
	sub $t5,$0,$t3
	addi $t5,$t5,5
	mul $t5,$t5,6
	add $t5,$t5,$t4
	mul $t5,$t5,4				# ((5-row)*6 + column) * 4 = $t5
	add $t5,$s0,$t5
	lw $t5,0($t5)				# $t4 = the stack offset to store the value
	bne $t5,0,badJump			# !board[r2][c2]
	
	add $t5,$t1,$t3
	srl $t5,$t5,1
	add $t6,$t2,$t4
	srl $t6,$t6,1
	
	sub $t5,$0,$t5
	addi $t5,$t5,5
	mul $t5,$t5,6
	add $t6,$t5,$t6
	mul $t6,$t6,4				# ((5-row)*6 + column) * 4 = $t5
	add $t6,$s0,$t6
	lw $t6,0($t6)				# $t4 = the stack offset to store the value
	bne $t6,3,badJumpTestRed		# (board[rm][cm]==3)
	j finish

badJumpTestRed:
	bne $t6,7,badJump			# (board[rm][cm]==7)
	j finish
	
badJumpTestWhite:
	bne $t6,5,badJump
	j finish
	
whiteJump:
	sub $t5,$t1,$t3
	bne $t5,2,badJump			# (r1-r2)==-2)
	sub $t5,$t2,$t4
	abs $t5,$t5
	bne $t5,2,badJump			# abs(c1-c2)==2
	
	sub $t5,$0,$t3
	addi $t5,$t5,5
	mul $t5,$t5,6
	add $t5,$t5,$t4
	mul $t5,$t5,4				# ((5-row)*6 + column) * 4 = $t5
	add $t5,$s0,$t5
	lw $t5,0($t5)				# $t4 = the stack offset to store the value
	bne $t5,0,badJump			# !board[r2][c2]
	
	add $t5,$t1,$t3
	srl $t5,$t5,1
	add $t6,$t2,$t4
	srl $t6,$t6,1
	
	sub $t5,$0,$t5
	addi $t5,$t5,5
	mul $t5,$t5,6
	add $t6,$t5,$t6
	mul $t6,$t6,4				# ((5-row)*6 + column) * 4 = $t5
	add $t6,$s0,$t6
	lw $t6,0($t6)				# $t4 = the stack offset to store the value
	bne $t6,1,badJumpTestWhite		# (board[rm][cm]==3)
	j finish
	
redKingJump:
	sub $t5,$t1,$t3
	abs $t5,$t5
	bne $t5,2,badJump			# (r1-r2)==-2)
	sub $t5,$t2,$t4
	abs $t5,$t5
	bne $t5,2,badJump			# abs(c1-c2)==2
	
	sub $t5,$0,$t3
	addi $t5,$t5,5
	mul $t5,$t5,6
	add $t5,$t5,$t4
	mul $t5,$t5,4				# ((5-row)*6 + column) * 4 = $t5
	add $t5,$s0,$t5
	lw $t5,0($t5)				# $t4 = the stack offset to store the value
	bne $t5,0,badJump			# !board[r2][c2]
	
	add $t5,$t1,$t3
	srl $t5,$t5,1
	add $t6,$t2,$t4
	srl $t6,$t6,1
	
	sub $t5,$0,$t5
	addi $t5,$t5,5
	mul $t5,$t5,6
	add $t6,$t5,$t6
	mul $t6,$t6,4				# ((5-row)*6 + column) * 4 = $t5
	add $t6,$s0,$t6
	lw $t6,0($t6)				# $t4 = the stack offset to store the value
	bne $t6,3,badJumpTestRed		# (board[rm][cm]==3)
	j finish
	
whiteKingJump:
	sub $t5,$t1,$t3
	abs $t5,$t5
	bne $t5,2,badJump			# (r1-r2)==-2)
	sub $t5,$t2,$t4
	abs $t5,$t5
	bne $t5,2,badJump			# abs(c1-c2)==2
	
	sub $t5,$0,$t3
	addi $t5,$t5,5
	mul $t5,$t5,6
	add $t5,$t5,$t4
	mul $t5,$t5,4				# ((5-row)*6 + column) * 4 = $t5
	add $t5,$s0,$t5
	lw $t5,0($t5)				# $t4 = the stack offset to store the value
	bne $t5,0,badJump			# !board[r2][c2]
	
	add $t5,$t1,$t3
	srl $t5,$t5,1
	add $t6,$t2,$t4
	srl $t6,$t6,1
	
	sub $t5,$0,$t5
	addi $t5,$t5,5
	mul $t5,$t5,6
	add $t6,$t5,$t6
	mul $t6,$t6,4				# ((5-row)*6 + column) * 4 = $t5
	add $t6,$s0,$t6
	lw $t6,0($t6)				# $t4 = the stack offset to store the value
	bne $t6,1,badJumpTestWhite		# (board[rm][cm]==3)
	j finish
	
badJump:
	li $v1,0
finish:
	lw $ra,0($sp)
	addi $sp,$sp,4
	jr $ra
	
	
	
	
isValidMove:
	lw $s0,16($sp)		# load pointer to checkerBoard in $s0
	lw $t1,12($sp)		# load the 2 pairs of coordinates in $t0 to $t3
	lw $t2,8($sp)
	lw $t3,4($sp)
	lw $t4,0($sp)			
	
	mov $a1,$t1			#check each pair of coords for validity
	mov $a2,$t2
	addi $sp,$sp,-4
	sw $ra,0($sp)
	jal isLegalPosition
	beq $v1,0,invalidMove
	
	mov $a1,$t3
	mov $a2,$t4
	jal isLegalPosition
	beq $v1,0,invalidMove
	
	sub $t5,$0,$t1
	addi $t5,$t5,5
	mul $t5,$t5,6
	add $t5,$t5,$t2
	mul $t5,$t5,4				# ((5-row)*6 + column) * 4 = $t1
	add $t5,$s0,$t5
	lw $t5,0($t5)				# $t0 = the stack offset to store the value
	
	li $v1,1
	beq $t5,1,red
	beq $t5,3,white
	beq $t5,5,redKing
	beq $t5,7,whiteKing
	j invalidMove

red:
	sub $t5,$t1,$t3
	bne $t5,-1,invalidMove
	sub $t5,$t2,$t4
	abs $t5,$t5
	bne $t5,1,invalidMove
	j emptySpaceCheck
	
white:
	sub $t5,$t1,$t3
	bne $t5,1,invalidMove
	sub $t5,$t2,$t4
	abs $t5,$t5
	bne $t5,1,invalidMove
	j emptySpaceCheck

redKing:
	sub $t5,$t1,$t3
	abs $t5,$t5
	bne $t5,1,invalidMove
	sub $t5,$t2,$t4
	abs $t5,$t5
	bne $t5,1,invalidMove
	j emptySpaceCheck

whiteKing:
	sub $t5,$t1,$t3
	abs $t5,$t5
	bne $t5,1,invalidMove
	sub $t5,$t2,$t4
	abs $t5,$t5
	bne $t5,1,invalidMove
	
emptySpaceCheck:
	sub $t3,$0,$t3
	addi $t3,$t3,5
	mul $t3,$t3,6
	add $t4,$t3,$t4
	mul $t4,$t4,4				# ((5-row)*6 + column) * 4 = $t1
	add $t4,$s0,$t4
	lw $t4,0($t4)				# $t2 = the stack offset to load the value
	bne $t4,0,invalidMove
	j end

invalidMove:
	li $v1,0
end:
	lw $ra,0($sp)
	addi $sp,$sp,4
	jr $ra




	
isLegalPosition:
	blt $a1,0,illegal
	blt $a2,0,illegal
	bgt $a1,5,illegal
	bgt $a2,5,illegal
	add $t0,$a1,$a2
	rem $t0,$t0,2
	beq $t0,0,illegal		#if the sum is even, it's a black square
	li $v1,1
	j next
illegal:
	li $v1,0
next:
	jr $ra 





	
board:
	addi $sp,$sp,-144				# (36 * 4) bytes of memory
	mov $s0,$sp					# store pointer to board in $s0
	mov $s1,$ra
	li $t3,1						# $t3 = red piece value
	li $t1,0						# $t1 = row
	j redTest1
redLoop1:
	li $t2,0						# $t2 = column
	j redTest2
redLoop2:
	mov $a1,$t1
	mov $a2,$t2
	jal isLegalPosition
	beq $v1,1,addRed
	j skipAddRed
addRed:							# ((5-row)*6 + column) * 4 = $t1
	sub $t4,$0,$t1
	addi $t4,$t4,5
	mul $t4,$t4,6
	add $t5,$t4,$t2
	mul $t5,$t5,4				# ((5-row)*6 + column) * 4 = $t1
	add $t5,$s0,$t5
	sw $t3,0($t5)				# $t0 = the stack offset to store the value
skipAddRed:
	addi $t2,$t2,1
redTest2:
	blt $t2,6,redLoop2
	addi $t1,$t1,1
redTest1:
	ble $t1,1,redLoop1
	
	li $t3,3						# $t3 = red piece value
	li $t1,4						# $t1 = row
	j whiteTest1
whiteLoop1:
	li $t2,0						# $t2 = column
	j whiteTest2
whiteLoop2:
	mov $a1,$t1
	mov $a2,$t2
	jal isLegalPosition
	beq $v1,1,addWhite
	j skipAddWhite
addWhite:							# ((5-row)*6 + column) * 4 = $t1
	sub $t4,$0,$t1
	addi $t4,$t4,5
	mul $t4,$t4,6
	add $t5,$t4,$t2
	mul $t5,$t5,4				# ((5-row)*6 + column) * 4 = $t1
	add $t5,$s0,$t5
	sw $t3,0($t5)				# $t0 = the stack offset to store the value
skipAddWhite:
	addi $t2,$t2,1
whiteTest2:
	blt $t2,6,whiteLoop2
	addi $t1,$t1,1
whiteTest1:
	ble $t1,5,whiteLoop1
	mov $ra,$s1
	jr $ra


	
displayBoard:	
	li $t0,0					# $t0 = count1 = 0
iloop:
	li $t1,0					# $t1 = count2 = 0
jloop:
	add $t2,$t0,$t1
	rem $t2,$t2,2
	
	bne $t2,0,else			#else print black square
	
	lw $a0,0($sp)
	beq $a0,3,lowercaseW
	beq $a0,1,lowercaseR
	beq $a0,5,capitalR
	beq $a0,7,capitalW
	
	li $a0,32					#print white square
	syscall $print_char
	j jtest
	
lowercaseW:
	la $a0,w
	syscall $print_string
	j jtest
lowercaseR:
	la $a0,r
	syscall $print_string
	j jtest
capitalR:
	la $a0,bigr
	syscall $print_string
	j jtest
capitalW:
	la $a0,bigw
	syscall $print_string
	j jtest
else:
	li $a0,219				#print black square
	syscall $print_char

jtest:
	addi $t1,$t1,1				#increment count2 by 1
	addi $sp,$sp,4
	blt $t1,6,jloop
	
	la $a0,nl
	syscall $print_string
	addi $t0,$t0,1				# increment count1 by 1
itest:
	blt $t0,6,iloop
	mov $sp,$s0
	jr $ra

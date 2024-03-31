# Rohan Solas -- 05/21/2023

# REFERENCES
# https://stackoverflow.com/questions/26320387/storing-a-very-large-string-in-a-mips-asciiz

# NOTES
# signed, sign extends
# unsigned, zero extends
# check registers used in macros

.include "macros.asm"

.text
main:
la $t0, copy_space
sw $t0, copy_top

# first input asks for initial state
# second input asks for goal state
# third input asks for the number of pieces to drop; save number in register num_pieces
	# create list chosen with length num_pieces; keeps track of which piece is used
	# create list of lists converted_pieces containing pieces converted to list of offset pairs
# fourth input onwards asks for the pieces to be dropped
	# convert each pieces to pairs
	
# answer = backtrack(start_grid, chosen, converted_pieces); returns 1 or 0
# if answer == 1: print(YES)
# else: print(NO)

### INITIAL STATE INPUT ###
# for loop for initial state
# update last 6 rows of start grid to be whatever the input is
la $t0, init_state
li $t1, 0
init_for:
 	beq $t1, 6, init_for_end
 	read_str($t0, 7)
 	# print_str(newline)
	addi $t0, $t0, 6 # ignore null terminator for each row
	addi $t1, $t1, 1
	j init_for
init_for_end:
li $t2, 0x00
sb $t2, 0($t0) # null terminator

la $a0, start_grid
jal freeze_blocks

### GOAL STATE INPUT ###
# for loop for goal state
# update last 6 rows of final grid to be whatever the input is
la $t0, goal_state
li $t1, 0
goal_for:
 	beq $t1, 6, goal_for_end
 	read_str($t0, 7)
 	# print_str(newline)
	addi $t0, $t0, 6 # ignore null terminator for each row
	addi $t1, $t1, 1
	j goal_for
goal_for_end:
li $t2, 0x00
sb $t2, 0($t0) # null terminator

la $a0, final_grid
jal freeze_blocks

### NUMBER OF PIECES INPUT ###
# get number of pieces, store in num_pieces
read_int(num_pieces)

### INITIALIZE CHOSEN LIST AND FILL WITH ZEROS ###
# create list of 0x00 store in chosen_list
# $t0 - False / 0x00
# $t1 - stores value of piece number; how many times to append to chosen_list
# $t2 - index in list
# $t3 - pointer to chosen_list
# $t4 - pointer to space in chosen_list
li $t0, 0x00
lw $t1, num_pieces
addi $t1, $t1, 1
li $t2, 0
la $t3, chosen_list
init_chosen:
beq $t2, $t1, init_chosen_end
add $t4, $t3, $t2
sb $t0, 0($t4)
addi $t2, $t2, 1
j init_chosen
init_chosen_end:
li $t0, 0xFF
sb $t0, 0($t4) # end of list

# la $a1, chosen_list
# lw $a2, num_pieces
# jal print_chosen_list

### PIECES INPUT AND CONVERSION ###
# convert each piece to pairs, store in converted_pieces
# $t0 - pointer to current space for 1 piece; add offset of 17 to store next piece
# $t1 - loop counter; i-th piece
# $t2 - number of pieces to enter; max of 5
# $t3 - inner loop counter; j-th row; increments by 4 since there are 4 spaces per row
# $t4 - pointer to a rowin a piece
la $t0, pieces
li $t1, 0
lw $t2, num_pieces
for_piece:
	beq $t1, $t2, for_piece_end
	li $t3, 0	
	input_piece:
		beq $t3, 16, input_piece_end
		add $t4, $t0, $t3
		read_str($t4, 5) # read input piece; store at address stored by $t4         
		# print_str(newline)
		addi $t3, $t3, 4
		j input_piece
	input_piece_end:
	# li $t5, 0x00
	# sb $t5, 1($t4) # 17th character of a piece; leaves gap between pieces
	
	# save registers conflicting with function to call
	move $s0, $t0
	move $s1, $t1 
	move $s2, $t2
	move $a1, $t0
	jal convert_piece_to_pairs # convert piece
	# retrieve original register values
	move $t0, $s0
	move $t1, $s1 
	move $t2, $s2
	bne $t1, 0, skip_heap_pointer # only runs next line during first iteration
		# $v0 stores pointer to segment containing converted pieces
		sw $v0, converted_pieces # do at the start; saves pointer to list of all converted pieces
	skip_heap_pointer:
	addi $t1, $t1, 1
	addi $t0, $t0, 17
	j for_piece
for_piece_end:

la $a0, start_grid # address to starting grid
la $a1, chosen_list # address to chosen list
lw $a2, converted_pieces # stores value of converted_pieces address; doesn't contain the list of pieces itself
jal backtrack
beq $v0, 0, not_possible
beq $v0, 1, possible
not_possible:
 	print_str(no)
	j end_compare
possible:
	print_str(yes)
end_compare:

exit()

############################
### FUNCTION DEFINITIONS ###
############################
is_equal_grids: # $a0, address to first byte of gridOne; $a1, address to first byte of gridTwo; assumes same size
	# $a0 - pointer to grid_one
	# $a1 - pointer to grid_two
	### preamble ###
	subi $sp, $sp, 32
	sw $s0, 28($sp)
	sw $s1, 24($sp)
	sw $s2, 20($sp)
	sw $s3, 16($sp)
	sw $s4, 12($sp)
	sw $s5, 8($sp)
	sw $s6, 4($sp)
	sw $ra, 0($sp)
	### preamble ###

	# $a0, $a1 should store pointers to each array's first elements
	# compare each byte (60 in total)
	# if encountered different byte values, return 1
	# else continue until end, return 0
	
	# $t2 and $t3 are lengths of grids in memory / used as loop counters
	addi $t2, $a0, 60 # 36; change to 60 later (size of whole grid)
	addi $t3, $a1, 60 
	check:
	beq $a0, $t2, eq # reached end of loop variable without branching to ineq -> grids are eq
	beq $a1, $t3, eq # one condition should suffice
	lbu $t0, 0($a0) 
	lbu $t1, 0($a1)
	bne $t0, $t1, ineq  
	addi $a0, $a0, 1 # move to next element
	addi $a1, $a1, 1
	j check
	ineq:
	li $v0, 0
	j eq_end
	eq:
	li $v0, 1
	
	eq_end:
	### end ###
	# $v0 is 1 or 0 (true or false)
	lw $s0, 28($sp)
	lw $s1, 24($sp)
	lw $s2, 20($sp)
	lw $s3, 16($sp)
	lw $s4, 12($sp)
	lw $s5, 8($sp)
	lw $s6, 4($sp)
	lw $ra, 0($sp)
	addi $sp, $sp, 32
	
	jr $ra
	### end ###


print_grid: # $a1, address to first byte of grid; print_char uses $a0
	# $a1 - pointer to grid
	### preamble ###
	subi $sp, $sp, 32
	sw $s0, 28($sp)
	sw $s1, 24($sp)
	sw $s2, 20($sp)
	sw $s3, 16($sp)
	sw $s4, 12($sp)
	sw $s5, 8($sp)
	sw $s6, 4($sp)
	sw $ra, 0($sp)
	### preamble ###
	
	# $t0 - check null terminator
	# $t1 - character to print
	# $t2 - address of newline
	# $t3 - loop counter
	# $t4 - branch condition
	li $t0, 0x00 # null terminator
	la $t2, newline
	li $t3, 1 # loop counter
	print_loop:
	lbu $t1, 0($a1) # load character to $t1
	beq $t1, $t0, end_print # encounter null terminator, end of grid
	rem $t4, $t3, 7 # if counter is at a value divisible by 6, print newline
	beq $t4, 0, print_newline
	print_val:
	print_char($a1)
	addi $a1, $a1, 1 # move to next element
	addi $t3, $t3, 1 # update counter
	j print_loop
	print_newline:
	print_char($t2)
	addi $t3, $t3, 1 # update counter
	j print_loop
	
	end_print:
	### end ###
	print_char($t2)
	# no return value; simply prints
	lw $s0, 28($sp)
	lw $s1, 24($sp)
	lw $s2, 20($sp)
	lw $s3, 16($sp)
	lw $s4, 12($sp)
	lw $s5, 8($sp)
	lw $s6, 4($sp)
	lw $ra, 0($sp)
	addi $sp, $sp, 32
	
	jr $ra
	### end ###
	

print_chosen_list: # $a1, list of true or false; $a2, size
	# $a1 - pointer to list
	# 00 for false
	# 01 for true
	# need to make sure end is FF?
	### preamble ###
	subi $sp, $sp, 32
	sw $s0, 28($sp)
	sw $s1, 24($sp)
	sw $s2, 20($sp)
	sw $s3, 16($sp)
	sw $s4, 12($sp)
	sw $s5, 8($sp)
	sw $s6, 4($sp)
	sw $ra, 0($sp)
	### preamble ###
	print_str(open_bracket) # [
	
	move $t1, $a1
	print_chosen_loop:
	lbu $t2, 0($t1)
	beq $a2, $0, print_chosen_end # end of list
	beq $t2, 0x00, print_false # 00 = false
	j print_true # else, 01 = true
	
	print_false:
	print_str(false)
	subi $t2, $a2, 1
	beq $t2, $0, print_chosen_end # next element is 0xFF, no need to print comma and space
	print_str(comma)
	print_str(white_space)
	j next_bool
	
	print_true:
	print_str(true)
	subi $t2, $a2, 1
	beq $t2, $0, print_chosen_end # next element is 0xFF, no need to print comma and space
	print_str(comma)
	print_str(white_space)
	
	next_bool:
	addi $t1, $t1, 1
	subi $a2, $a2, 1
	j print_chosen_loop
	print_chosen_end:
	
	print_str(close_bracket) # ]
	print_str(newline)
	### end ###
	# no return value; simply prints
	lw $s0, 28($sp)
	lw $s1, 24($sp)
	lw $s2, 20($sp)
	lw $s3, 16($sp)
	lw $s4, 12($sp)
	lw $s5, 8($sp)
	lw $s6, 4($sp)
	lw $ra, 0($sp)
	addi $sp, $sp, 32
	
	jr $ra
	### end ###
	
freeze_blocks: # $a0, grid	
	# $a0 - pointer to grid
	### preamble ###
	subi $sp, $sp, 32
	sw $s0, 28($sp)
	sw $s1, 24($sp)
	sw $s2, 20($sp)
	sw $s3, 16($sp)
	sw $s4, 12($sp)
	sw $s5, 8($sp)
	sw $s6, 4($sp)
	sw $ra, 0($sp)
	### preamble ###
	
	# $t0 - loop end condition 
	# $t1 - current block
	addi $t0, $a0, 60 # change to 60 later (size of whole grid)
	freeze_iter:
	beq $a0, $t0, end_freeze 
	lbu $t1, 0($a0) 
	beq $t1, 0x23, freeze # found a "#" block character
	j next_elem
	freeze:
	li $t1, 0x58 # turn "#" to "X"
	sb $t1, 0($a0)
	next_elem:
	addi $a0, $a0, 1 # move to next element
	j freeze_iter

	end_freeze:
	subi $a0, $a0, 60 # return back pointer to first element of grid (initial $a0)
	move $v0, $a0 # return grid
	
	### end ###
	# $v0 stores pointer to grid
	lw $s0, 28($sp)
	lw $s1, 24($sp)
	lw $s2, 20($sp)
	lw $s3, 16($sp)
	lw $s4, 12($sp)
	lw $s5, 8($sp)
	lw $s6, 4($sp)
	lw $ra, 0($sp)
	addi $sp, $sp, 32
	
	jr $ra
	### end ###


get_max_x_of_piece: # $a0, piece; piece is represented by a list of coordinates of the blocks; and a block is represented by its coordinates 
	# $a0 - pointer to piece
	### preamble ###
	subi $sp, $sp, 32
	sw $s0, 28($sp)
	sw $s1, 24($sp)
	sw $s2, 20($sp)
	sw $s3, 16($sp)
	sw $s4, 12($sp)
	sw $s5, 8($sp)
	sw $s6, 4($sp)
	sw $ra, 0($sp)
	### preamble ###

	# $t0 - pointer to current block
	# $t1 - loop variable
	# $t2 - max_x
	# $t3 - x_offset
	li $t2, -1 # $s1 stores max_x
	move $t0, $a0 # load address of current block/coordinate to $t0
	# $t0 initally points to y_offset first
	# we want it to point to x_offset which is stored next to it, so we add 1
	addi $t0, $t0, 1 # now, we can iterate using this while always pointing to the x_offset
	addi $t1, $0, 0 # loop variable
	max_iter: # $s1 stores x_offset; $t0 is pointer 
	beq $t1, 4, end_max # since piece comes in 4 blocks always, can assume that there will be 4 iterations
	lbu $t3, 0($t0) # address offset already calculated beforehand, so offset is 0
	bgt $t3, $t2, new_max
	j next_coor 
	new_max:
	move $t2, $t3 # x_offset becomes new max_x
	next_coor: # else max_x is same; new_max is skipped
	addi $t0, $t0, 2 # move to next point/block, comes in 2 bytes for each offset
	addi $t1, $t1, 1 # update loop counter
	j max_iter
	# if max_x > x_coor of current block/coor, keep max_x
	# else x_coor becomes new max_x
	# go to next block/coor
	end_max:
	move $v0, $t2 # return max_x
	
	### end ###
	# $v0 stores biggest x_offset
	lw $s0, 28($sp)
	lw $s1, 24($sp)
	lw $s2, 20($sp)
	lw $s3, 16($sp)
	lw $s4, 12($sp)
	lw $s5, 8($sp)
	lw $s6, 4($sp)
	lw $ra, 0($sp)
	addi $sp, $sp, 32
	
	jr $ra
	### end ###


deepcopy: # $a1, array; $a2, size
	# $a1 -  pointer to array to copy
	# $a2 - size of array
	### preamble ###
	subi $sp, $sp, 32
	sw $s0, 28($sp)
	sw $s1, 24($sp)
	sw $s2, 20($sp)
	sw $s3, 16($sp)
	sw $s4, 12($sp)
	sw $s5, 8($sp)
	sw $s6, 4($sp)
	sw $ra, 0($sp)
	### preamble ###
	
	# $t1 - pointer to space to fill
	# $t2 - loop break condition
	# $t3 - element loading and storing
	# move $t0, $sp # save stack frame pointer
	 
 	lw $t1, copy_top # pointer to storage space
 	move $v0, $t1 # return pointer to copy
 	move $t2, $a2 # size
 	copy_loop:
 	lbu $t3, 0($a1)
 	sb $t3, 0($t1)
 	addi $a1, $a1, 1 # next byte to copy
 	addi $t1, $t1, 1 # next storage space
 	subi $t2, $t2, 1 # decrease size to copy
 	bnez $t2, copy_loop
 	
	sw $t1, copy_top # update copy_top
	 
	### end ###
	# $v0 stores pointer to copy in data segment
	lw $s0, 28($sp)
	lw $s1, 24($sp)
	lw $s2, 20($sp)
	lw $s3, 16($sp)
	lw $s4, 12($sp)
	lw $s5, 8($sp)
	lw $s6, 4($sp)
	lw $ra, 0($sp)
	addi $sp, $sp, 32
	
	jr $ra
	### end ###
	
free: # $a0, size to free in copy space
	### preamble ###
	subi $sp, $sp, 32
	sw $s0, 28($sp)
	sw $s1, 24($sp)
	sw $s2, 20($sp)
	sw $s3, 16($sp)
	sw $s4, 12($sp)
	sw $s5, 8($sp)
	sw $s6, 4($sp)
	sw $ra, 0($sp)
	### preamble ###
	
	lw $t0, copy_top
	sub $t0, $t0, $a0
	sw $t0, copy_top
	
	### end ###
	# doesn't return anything, just frees up space
	lw $s0, 28($sp)
	lw $s1, 24($sp)
	lw $s2, 20($sp)
	lw $s3, 16($sp)
	lw $s4, 12($sp)
	lw $s5, 8($sp)
	lw $s6, 4($sp)
	lw $ra, 0($sp)
	addi $sp, $sp, 32
	
	jr $ra
	### end ###
	
	
drop_piece_in_grid: # $a1, grid; $a2, piece; $a3, xOffset
	# $a1 - pointer to grid
	# $a2 - pointer to piece represented as list of pairs
	# $a3 - number to add to x offset
	### preamble ###
	subi $sp, $sp, 32
	sw $s0, 28($sp)
	sw $s1, 24($sp)
	sw $s2, 20($sp)
	sw $s3, 16($sp)
	sw $s4, 12($sp)
	sw $s5, 8($sp)
	sw $s6, 4($sp)
	sw $ra, 0($sp)
	### preamble ###
	
	# DEEPCOPY / SET MAX_Y #
	# make copy of grid; for every byte starting from val stored in $a0, store in heap until encounter null terminator -> create deepcopy function
	# set max_y to 100
	# $s7 - pointer to grid_copy
	# $t0 - max_y
	
	# save registers conflicting with function to call
	move $s0, $a1
	move $s1, $a2
	# $a1 is already grid
	li $a2, 61 # include null terminator
	jal deepcopy # uses $a1, $a2, $t0-$t3 -> drop_piece uses $a1, $a2
	# retrieve original register values
	move $a1, $s0
	move $a2, $s1
	# $v0 stores pointer to copy of grid
	li $t0, 100 
	
	# PLACE PIECE IN GRID #
	# loop for every block in piece
		# put block in grid, [y_offset][x_offset + additional offset]
		# only active blocks are '#'; frozen blocks are 'X'
	# $t1 - y_offset; block[0]
	# $t2 - x_offset; block[1]
	# $t3 - pointer to each offset pair
	# $t4 - loop condition
	# $t5 - pointer to which blocks will be placed in grid_copy
	# $t6 - 0x23
	move $t3, $a2
	addi $t4, $a2, 8
	li $t6, 0x23
	place_block:
	beq $t3, $t4, block_placed # there are 4 blocks in every piece, each with y and x offsets
	lbu $t1, 0($t3) # get y offset
	mul $t1, $t1, 6 # since one row of the grid is 6 chars long
	lbu $t2, 1($t3) # get x offset
	add $t5, $v0, $t1 # [block[0]]
	add $t5, $t5, $t2 # [block[0]][block[1]]
	add $t5, $t5, $a3 # [block[0]][block[1] + xOffset]
	sb $t6, 0($t5)
	addi $t3, $t3, 2
	j place_block
	block_placed:
			
	# WHILE LOOP #		
	# $t1 - loop condition
	# $t2 - can_still_go_down	
	# loop while 1
		# can still go down = 1
	li $t1, 1
	go_down_loop: # while true
	beq $t1, 0, go_down_end # if false, break
	li $t2, 1 # canstillgodown = true
	
	# CHECK FOR BOTTOM OR FROZEN BLOCKS #
	# $t3 - first loop break condition
	# $t4 - pointer to elements in grid_copy
	# $t5 - value of element
	# $t6 - stores i + 1
	# $t7 - j
	# $t8 - [i + 1][j]
	# $t9 - grid_copy[i + 1][j]
	# for every space in grid
			# if [y_offset + 1] = 10 OR gridcopy[y_offset + 1][x_offset] = 'X'
				# block has reached bottom of grid or encountered frozen block
				# can still go down = 0
	addi $t3, $v0, 60 # address of last element in grid_copy is $s4 + 59 offset
	move $t4, $v0 # copy pointer to grid-copy
	check_bot:
	beq $t4, $t3, check_bot_end
	lbu $t5, 0($t4)
	beq $t5, 0x23, and_cond # if gridCopy[i][j] == '#' 
	addi $t4, $t4, 1 # else go to next space
	j check_bot
		and_cond: # and (i + 1 == 10 
		sub $t6, $t4, $v0 # address to cur element - address to grid_copy; answer is a number from 0 to 59
		rem $t7, $t6, 6 # j
		div $t6, $t6, 6 # check what row block is on; i
		addi $t6, $t6, 1 # i + 1
		beq $t6, 10, cant_go_down
		or_cond: # or gridCopy[i + 1][j] == 'X')
		mul $t6, $t6, 6
		add $t8, $v0, $t6 # grid_copy[i + 1]
		add $t8, $t8, $t7 # grid_copy[i + 1][j]
		lbu $t9, 0($t8)
		beq $t9, 0x58, cant_go_down
		
		add $t4, $t4, 1 # check next element
		j check_bot
		cant_go_down:
		li $t2, 0 # canstillgodown = 0
	check_bot_end:
	
	# IF CAN STILL GO DOWN, PIECE GOES DOWN # 
	# $t3 - i
	# $t4 - j
	# $t5 - pointer to element in grid_copy
	# $t6 - value at grid_copy[i][j]
	# if can still go down
			# move cells of piece down, starting from bottom cells; from y_offset 8 to 0 of grid
				# move cells down one space
				# block moves down
				# previous location of block becomes vacant
	beq $t2, 1, can_go_down # if can still go down
	j go_down_break # else break
	
	can_go_down:
	addi $t3, $0, 8 # for i in range(8, -1, -1)
	go_down_i:
	beq $t3, -1, go_down_i_end
		addi $t4, $0, 0 # for j in range(6)
		go_down_j:
		mul $t3, $t3, 6 # since every row i has 6 elements
		beq $t4, 6, go_down_j_end
	
		add $t5, $v0, $t3 # grid_copy[i]
		add $t5, $t5, $t4 # grid_copy[i][j]
		lbu $t6, 0($t5) # load value
		beq $t6, 0x23, go_down # if grid_copy[i][j] == "#"
		addi $t4, $t4, 1 # else go to next column
		div $t3, $t3, 6 # get back i
		j go_down_j
			go_down:
			div $t3, $t3, 6 # get i
			addi $t3, $t3, 1 # i + 1
			mul $t3, $t3, 6 # since rows are stored sequentially / every row i has 6 elements
			add $t7, $v0, $t3 # [i + 1]
			add $t7, $t7, $t4 # [i + 1][j]
			li $t8, 0x23
			sb $t8, 0($t7) # grid_copy[i + 1][j] = "#"
			
			div $t3, $t3, 6
			subi $t3, $t3, 1 # reverse operations on $t3 to get back i
			mul $t3, $t3, 6
			add $t7, $v0, $t3 # [i]
			add $t7, $t7, $t4 # [i][j]
			li $t8, 0x2e
			sb $t8, 0($t7) # grid_copy[i][j] = "."
		addi $t4, $t4, 1
		div $t3, $t3, 6 # get back i
		j go_down_j
		go_down_j_end:
	div $t3, $t3, 6
	subi $t3, $t3, 1
	j go_down_i
	go_down_i_end:
	j if_else_end
	
	# ELSE BREAK #
	# else
			# break while loop (set reg value to 0)
	go_down_break:
		li $t1, 0
	if_else_end:
	j go_down_loop
	
	go_down_end:
	
	# GET MAX_Y #
	# for every block already in grid
		# find y_offset of topmost block(?)
		# set max_y to smallest y_offset (topmost block)
	# $t3 - loop end condition
	# $t4 - pointer to each element in grid
	# $t5 - dest reg for grid values
	# $t6 - i or y_offset
	addi $t3, $v0, 60
	move $t4, $v0
	get_max_y:
	beq $t4, $t3, get_max_y_end
	lbu $t5, 0($t4)
	beq $t5, 0x23, check_max_y
	addi $t4, $t4, 1 # else, check next
	j get_max_y
	check_max_y:
	# $t0 is max_y
	# $t6 is i
	sub $t6, $t4, $v0 # pointer to current block - pointer to whole grid; gets relative distance
	div $t6, $t6, 6
	blt $t6, $t0, new_max_y # i < max_y
	j same_max_y
	new_max_y:
	move $t0, $t6
	addi $t4, $t4, 1
	j get_max_y
	same_max_y:
	# $t0 is still previous $t0
	addi $t4, $t4, 1
	j get_max_y
	get_max_y_end:
	
	# RETURN VALUES #
	# if max_y <= 3
		# piece protrudes from top of 6x6 grid; top of piece has offset <= 3
		# illegally placed piece
		# $v0 stores pointer to grid
		# $v1 stores false (0)
	# else
		# else, valid piece placement
		# $v0 stores pointer to grid with placed piece
		# $v1 stores true (1)			
	ble $t0, 3, ret_grid
	j ret_grid_copy
	ret_grid:
	move $s0, $a1
	li $a0, 61
	jal free
	move $a1, $s0
	
	move $v0, $a1 # return grid
	li $v1, 0 # return False
	j drop_piece_end
	
	ret_grid_copy:
	move $a0, $v0
	jal freeze_blocks # return freeze_blocks(grid_copy)
	addi $v0, $v0, 0
	li $v1, 1 # return True

	drop_piece_end:
	### end ###
	lw $s0, 28($sp)
	lw $s1, 24($sp)
	lw $s2, 20($sp)
	lw $s3, 16($sp)
	lw $s4, 12($sp)
	lw $s5, 8($sp)
	lw $s6, 4($sp)
	lw $ra, 0($sp)
	addi $sp, $sp, 32
	
	jr $ra
	### end ###


convert_piece_to_pairs: # $a1, pieceGrid; malloc uses $a0
	# $a1 - pointer to piece_grid
	# used during piece input; need to preserve values after calling convert
	### preamble ###
	subi $sp, $sp, 32
	sw $s0, 12($sp)
	sw $s1, 8($sp)
	sw $s2, 4($sp)
	sw $ra, 0($sp)
	### preamble ###

	# move $t0, $a0, loop variable to check each byte
	# while value != 0x00 (null terminator)
	# check value
	# if value is 0x23 (#), get offsets and store in s registers
	# store values of s registers in memory (but where)
	# else move on to next byte

	# $t0 - pointer to char
	# $t1 - null terminator
	# $t2 - pointer to start of allocated space in heap
	# $s0 $t3 - value of char
	# $s2 $t4 - intermediate value to get y_offset and eventually stores y_offset
	# $s3 $t5 - x_offset
	move $t0, $a1 # loop variable
	li $t1, 0x00 # null terminator
	malloc(8) # allocate memory for list; 2 for x and y offset * 4 for each block in a piece (based on given configs)
	# $v0 now points to array
	move $t2, $v0 # move pointer to temp register
	
	convert_loop:
	lbu $t3, 0($t0) # get next char
	beq $t3, $t1, convert_done # if current char is null terminator, end of piece
	beq $t3, 0x23, get_offset # if current char is #, get offset
	j next_block # else, go to next byte/char

	get_offset:
	y_offset: # $t4 stores y offset
	sub $t4, $t0, $a1 # address of cur_block - address of piece 
	div $t4, $t4, 4 # divide difference by 4
	x_offset: # $t5 stores x offset
	# remainder of y offset operation
	sub $t5, $t0, $a1 # address of cur_block - address of piece 
	rem $t5, $t5, 4 # divide difference by 4, and get remainder

	# store offsets somewhere sequentially
	# since $s1 and $s2 simply takes values from 0 to 3, 2 bytes is enough to store one point (y_offset, x_offset)
	sb $t4, 0($t2)
	sb $t5, 1($t2)
	addi $t2, $t2, 2 # point to next available space in array
	
	next_block:
	addi $t0, $t0, 1 # point to next block
	j convert_loop
	
	convert_done:
	### end ###
	# $v0 points to address of list of pairs in heap
	lw $s0, 12($sp)
	lw $s1, 8($sp)
	lw $s2, 4($sp)
	lw $ra, 0($sp)
	addi $sp, $sp, 32
	
	jr $ra
	### end ###
	
	
backtrack: # $a0, currGrid; $a1, chosen; $a2, pieces
	# $a0 - pointer to curr_grid
	# $a1 - pointer to chosen list
	# $a2 - pointer to list of pieces
	### preamble ###
	subi $sp, $sp, 36
	sw $s0, 32($sp)
	sw $s1, 28($sp)
	sw $s2, 24($sp)
	sw $s3, 20($sp)
	sw $s4, 16($sp)
	sw $s5, 12($sp)
	sw $s6, 8($sp)
	sw $s7, 4($sp)
	sw $ra, 0($sp)
	### preamble ###
	
	# $t0 - result
	# print(chosen)
	# print_grid(currGrid)
    	# print()
    	# result = False
    	
    	# move $s0, $a0
    	# move $s1, $a1
    	# move $s2, $a2
    	# move $s3, $t1
    	# move $s4, $t2
    	# move $s5, $t3
    	# move $s6, $t4
    	# $a1 is chosen list
    	# lw $a2, num_pieces
    	# jal print_chosen_list # no return value; uses $a1, $t1, $t2, $t3, $t4               -> still unused by backtrack
    	# move $a0, $s0
    	# move $a1, $s1
    	# move $a2, $s2
    	# move $t1, $s3
    	# move $t2, $s4
    	# move $t3, $s5
    	# move $t4, $s6
    	
    	# move $s0, $a0
    	# move $s1, $a1
    	# move $s2, $t0
    	# move $s3, $t1
    	# move $s4, $t2
    	# move $s5, $t3
    	# move $a1, $a0
    	# jal print_grid # no return value; uses $a1, $t0, $t1, $t2, $t3                           -> still unused by backtrack
    	# print_str(newline)
    	# move $a0, $s0
    	# move $a1, $s1
    	# move $t0, $s2
    	# move $t1, $s3
    	# move $t2, $s4
    	# move $t3, $s5
    	
    	li $t0, 0 # result = False
    	
   	# if is_equal_grids(currGrid, final_grid):
        	# return True
        move $s0, $a0
        move $s1, $a1
        move $s2, $t0
	# $a0 is already curr_grid
	la $a1, final_grid
	jal is_equal_grids # is_equal(curr_grid, final_grid); uses $a0, $a1, $t0, $t1, $t2, $t3           -> $a0, $a1, $t0 used by backtrack
	move $a0, $s0
	move $a1, $s1
	move $t0, $s2
	beq $v0, 1, backtrack_end # if the two grids are equal, return True
	j backtrack_next_step

	
	# $t1 - i
	# $t2 - length(chosen) = num_pieces
	# $t3 - pointer to element in chosen
	# $t4 - element in chosen
	# $t5 - address of pieces[i]
	# $t6 - offset
	# $t7 - 6 - max_x_of_piece
	# $t8 - 0x01, store true in chosen_copy[i]
	# $t9 - address of chosen_copy[i]
	# $s3 - max_x_of_piece
	# $s4 - chosen_copy
	# $s5 - next_grid
	# $s6 - success
	# for i in range(len(chosen)):
        # if not chosen[i]:
          	# max_x_of_piece = get_max_x_of_piece(pieces[i])
            	# chosenCopy = deepcopy(chosen)  # copy of chosen
            	# for offset in range(6 - max_x_of_piece):
               		# nextGrid, success = drop_piece_in_grid(currGrid, pieces[i], offset)
                	# if success:
                    		# chosenCopy[i] = True
                    		# result = result or backtrack(nextGrid, chosenCopy, pieces)
                   		# if result:
                       			# return True
    	# return result
	backtrack_next_step:
	# for loop here; from $t1 to $t2
	li $t1, 0
	backtrack_for:
	lw $t2, num_pieces # store length of chosen = num_pieces
	beq $t1, $t2, backtrack_for_end
	add $t3, $a1, $t1 # address of chosen[i]
	lbu $t4, 0($t3) # some value 0x00 (False) or 0x01 (True)
	beq $t4, 0x00, not_chosen # if not chosen[i] == if not False == if True == branches if chosen[i] is 0x00
	j backtrack_next_iter # else chosen[i] is true
		not_chosen:
		mul $t1, $t1, 8 # since each piece is stored as 2 words in heap
		add $t5, $a2, $t1 # address of pieces[i]
		div $t1, $t1, 8
		
		move $s0, $a0
		move $s1, $t0
		move $s2, $t1
		move $s3, $t2
		move $s4, $t3
		move $a0, $t5 
		jal get_max_x_of_piece # get_max_x_of_piece(pieces[i]); uses $a0, $t0, $t1, $t2, $t3                  -> $a0, $t0, $t1 used by backtrack
		move $a0, $s0
		move $t0, $s1
		move $t1, $s2
		move $t2, $s3
		move $t3, $s4
		
		move $s3, $v0 # $s3 stores max x of piece
	
	
		move $s0, $a0
		move $s1, $a1
		move $s2, $a2 
		# $s3 stores max x of piece
		move $s4, $t0
		move $s5, $t1
		move $s6, $t2
		move $s7, $t3
		move $a1, $s1 # address of chosen
		lw $a2, num_pieces # length of chosen
		addi $a2, $a2, 1 # so that deepcopy includes chosen_list terminator 0xFF 
		jal deepcopy # uses $a0, $a1, $a2, $t0, $t1, $t2, $t3               -> $a0, $a1, $s2, $t0, $t1, $t2, $t3 used by backtrack
		move $a0, $s0
		move $a1, $s1
		move $a2, $s2
		# recover value of $s3
		move $t0, $s4
		move $t1, $s5
		move $t2, $s6
		move $t3, $s7
		
		move $s4, $v0 # $s4 stores address to chosen_copy
	
	
			
			li $t6, 0 # load 0; keeps track of offset
			backtrack_inner_for:
			li $t8, 6 # load 6 to compute 6 - max_x
			sub $t7, $t8, $s3 # 6 - max_x
			# inner for loop here; from $t6 to $t7
			beq $t6, $t7, backtrack_inner_for_end
		
			# calculate $t5 again since it's not actually saved 	
			mul $t1, $t1, 8 # since each piece is stored as 2 words in heap
			add $t5, $a2, $t1 # address of pieces[i]
			div $t1, $t1, 8
			
			move $s0, $a0
			move $s1, $a1
			move $s2, $a2
			# $s3 stores max_x_of_piece
			# $s4 stores address to chosen_copy
			move $s5, $t0
			move $s6, $t1
			move $s7, $t6 
			move $a1, $s0 # curr_grid
			move $a2, $t5 # pieces[i]
			move $a3, $t6 # offset
			jal drop_piece_in_grid # uses $a0-$a3, $t0-$t9             -> $a0-$a2, $t0, $t1, $t6 used by backtrack
			# $v0 stores next_grid; pointer to updated grid
			# $v1 stores success; 0 or 1
			move $a0, $s0
			move $a1, $s1
			move $a2, $s2
			# $s3
			# $s4
			move $t0, $s5
			move $t1, $s6
			move $t6, $s7
		
			beq $v1, 0x01, success
			j inner_for_next
			success: # if success
			li $t8, 0x01
			add $t9, $s4, $t1 # address of chosen_copy[i]
			sb $t8, 0($t9) # chosen_copy[i] = true
			beq $t0, 0x01, if_result # or condition not needed since result is already true
			# if result is 0x00, check result of backtrack
			
			move $s0, $a0
			move $s1, $a1
			move $s2, $a2
			# $s3
			# $s4
			move $s5, $t0
			move $s6, $t1
			move $s7, $t6
			move $a0, $v0 # next_grid
			move $a1, $s4 # chosen_copy
			# $a2 is pieces
			jal backtrack # returns 0x01 or 0x00; uses $t0-$t9                              -> all $t0-$t9 used by backtrack
			move $a0, $s0
			move $a1, $s1
			move $a2, $s2
			# $s3
			# $s4
			move $t0, $s5
			move $t1, $s6
			move $t6, $s7
			move $t0, $v0 # result = backtrack if old_result = false
			
			
			beq $t0, 0, inner_for_next # result = result or backtrack = 0x00 both sides in or are false; won't return true
				if_result: # else, return true if either result or backtrack is true
				li $v0, 1
				
				move $s0, $a0
				move $s1, $t0
				lw $a0, num_pieces
				addi $a0, $a0, 1
				jal free # uses $a0, $t0
				move $a0, $s0
				move $t0, $s1
				
				j backtrack_end # return true
			inner_for_next:
			addi $t6, $t6, 1
			j backtrack_inner_for
	
			backtrack_inner_for_end:
	backtrack_next_iter:
	addi $t1, $t1, 1
	j backtrack_for
	
	backtrack_for_end:
	move $v0, $t0 # return result
	
	backtrack_end:
	move $s0, $a0
	move $s1, $t0
	li $a0, 60
	jal free # uses $a0, $t0
	move $a0, $s0
	move $t0, $s1
	
	### end ###
	lw $s0, 32($sp)
	lw $s1, 28($sp)
	lw $s2, 24($sp)
	lw $s3, 20($sp)
	lw $s4, 16($sp)
	lw $s5, 12($sp)
	lw $s6, 8($sp)
	lw $s7, 4($sp)
	lw $ra, 0($sp)
	addi $sp, $sp, 36
	
	jr $ra
	### end ###
	
.data
### ASCII CHARACTERS ###       
# each character is a byte (values in hex)
# . is 2e
# # is 23
# X is 58
# \n is 0a
# \0 is 00
some_num: .word 0x02 # temp storage for some number I want to print
yes: .asciiz "YES\n"
no: .asciiz "NO\n"
true: .asciiz "True"
false: .asciiz "False"
open_bracket: .asciiz "["
close_bracket: .asciiz "]"
comma: .asciiz ","
white_space: .asciiz " "
newline: .asciiz "\n"

### GRID AND PIECES ###

start_grid: # actually the top of the grid where pieces will initially be placed; remove 6 rows later
.ascii "......" # 0
.ascii "......" # 1
.ascii "......" # 2
.ascii "......" # 3
allocate_bytes(init_state, 37) # plus null terminator; address of start_grid + 24; topmost of the visible grid; will be replaced by user input

final_grid: # actually the top of the grid where pieces will initially be placed; remove 6 rows later
.ascii "......"
.ascii "......"
.ascii "......"
.ascii "......"
allocate_bytes(goal_state, 37) # address of final_grid + 24; topmost of the visible grid; will be replaced by user input

num_pieces: .word 0x0

chosen_list: # Maximum of 5 pieces = Maximum of 5 elements in chosen
.word 0x00000000
.word 0x00000000

converted_pieces: # stores pointer to pieces as pairs; access next piece by adding +8 to pointer
.word 0x00000000

pieces:
.space 85 # Maximum of 5 pieces, each with 16 + 1 (null terminator) bytes = 17 * 5 = 85; access next piece by adding offset of 18

### COPY SPACE ###

copy_top: .word 0x0

copy_space: .space 1048576







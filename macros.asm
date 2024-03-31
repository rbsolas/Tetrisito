# Rohan Solas -- 05/21/2023

# do syscall with code 'n'
.macro do_syscall(%n)
	li $v0, %n
	syscall
.end_macro

# exit()
.macro exit
	do_syscall(10)
.end_macro

# malloc()
.macro malloc(%bytes)
	add $a0, $0, %bytes
	do_syscall(9)
.end_macro

# print string stored in 'variable' named 'label'
.macro print_str(%label)
	la $a0, %label
	do_syscall(4)
.end_macro

# print single char
.macro print_char(%reg)
	lbu $a0, (%reg)
	do_syscall(11)
.end_macro

# take input of length 'len' and store in variable with 'label'
.macro read_str(%reg, %len)
	move $a0, %reg
	li $a1, %len
	do_syscall(8)
.end_macro

.macro print_int(%label)
	la $t9, %label
	lw $a0, 0($t9)
	do_syscall(1)
.end_macro

.macro read_int(%label)
	do_syscall(5)
	sw $v0, %label
.end_macro

# create variable named 'label' to store 'n' bytes of e.g. input
.macro allocate_bytes(%label, %n)
	%label: .space %n
.end_macro



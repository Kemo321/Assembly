	.data
filename: .asciz "test.bmp"

prompt1: .asciz "Enter image width:\n"
prompt2: .asciz "Enter image height:\n"

	.text
	.global main
main:
	#############################################################################################################
	# User input 
	#############################################################################################################
	# Print prompt1
	li a7, 4
	la a0, prompt1
	ecall
	# Read image width
	li a7, 5
	ecall
	mv s3, a0 # Save image width to s3


	# Print prompt1
	li a7, 4
	la a0, prompt2
	ecall
	# Read image heigth
	li a7, 5
	ecall
	mv s4, a0 # Save image height to s4
	#############################################################################################################
	# Padding
	#############################################################################################################
	# Copy width to t0
	mv t0, s3
	
	# Change width in pixels to width in bytes
	li t1, 3
	mul t0, t0, t1
	
	andi t1, t0, 3 # Move width % 4 to t1
	beq t1, zero, skip_padding # If width % 4 == 0: skip padding
	li t2, 4 # For comparison
	sub t1, t2, t1 # Set t1 to padding bytes number (t1 = 4 - (width % 4))
	#############################################################################################################
	# Opening the file, allocating memory and reading file into the buffer.
	#############################################################################################################
skip_padding:
	mv s5, t1 # Save padding number to s5
	add t0, t0, t1 # t0 = width(in bytes) + padding bytes
	mul t0, t0, s4 # (width(in bytes) + padding bytes) * heigth
	addi t0, t0, 54 # Add header size
	# Allocate heap memory
	li a7, 9
	mv a0, t0 # t0 = size of the buffer
	ecall
	# Save memory address in s1
	mv s1, a0
	# Open test.bmp file
	li a7, 1024
	la a0, filename
	li a1, 0
	ecall
	mv s2, a0 # Save file descriptor for later
	# Read file content into heap buffer
	li a7, 63
	mv a1, s1
	mv a2, t0
	ecall
	# Close file
	li a7, 57
	mv a0, s2
	ecall
	
	# Save file size for later
	mv s6, t0 
	#############################################################################################################
	# File header
	#############################################################################################################
	# Overwrite file size
	mv t2, s1 # Load buffer address to t2
	addi t2, t2, 2 # Point at file size
	jal store_4_bytes_little_endian
	
	# Overwrite image size
	mv t2, s1
	addi t2, t2, 34
	addi t0, t0, -54
	jal store_4_bytes_little_endian
	
	# Overwrite image width
	mv t2, s1
	addi t2, t2, 18
	mv t0, s3
	jal store_4_bytes_little_endian
	
	# Overwrite image height
	mv t2, s1
	addi t2, t2, 22
	mv t0, s4
	jal store_4_bytes_little_endian
	
	#############################################################################################################
	# Fractal generation
	#############################################################################################################
	
	#Initialize loop
	mv t0, s1 # t0 points to image buffer
	addi t0, t0, 54 # Move t0 to start of the pixel array
	
	li t1, 0 # x
	li t2, 0 # y
	li t3, 0 # iterations
	li t4, 0 # |z|
	li t5, 0 # padding counter
	li t6, 12 # shift right value for fixed point
	
	# s1 = Buffer address
	# s2 = File descriptor
	# s3 = width
	# s4 = height
	# s5 = padding bytes number
	# s6 = file size
	
	# Width interval = 4 (20/12 fp) / width
	li s7, 0x00004000
	div s7, s7, s3
	
	# Height interval = 4 (20/12 fp) / height
	li s8, 0x00004000 
	div s8, s8, s4

	li s9, -0x00002000 # Width for calculation (from -2 to 2) inf fixed point 20/12
	li s10, -0x00002000 # Height for calculation (from -2 to 2) in fixed point 20/12
	li s11, 254 # Max iterations
	
	li a0, 0x04000000 # 0x00004000 Threshold 4 in fixed point 8/24
	# a1 = current iteration real part
	# a2 = current iteration imaginary part
	# a3 - used to calculate ab*2 and later to calculate (a^2 - b^2 + c_real)^2
	# a4 - used to calculate (ab*2 + c_imaginary)^2
	li a6, -0x00C80000 # C real = -0.78125 in fixed point 8/24
	li a7, 0x00280000 # C imaginary = 0.15625 in fixed point 8/24
	
	
	
loop_x:
	
	li t3, 0 # Iteration = 0
	mul a1, s7, t1 # a1 = width interval * current x
	add a1, a1, s9 # a1 += base width for calculation (-2 in fixed point)
	
	mul a2, t2, s8 # a2 = height interval * current y 
	add a2, a2, s10 # a2 += base height for calculation (-2 in fixed point)
	
	addi t1, t1, 1 # Increment x (its not used for calculations, a1 is)
	
iterate_fractal:
	addi t3, t3, 1 # Increment iteration
	bgt t3, s11, store_byte # If iteration > max iterations store byte
	
	mul a3, a1, a2 # a3 = ab
	li t6, 1
	sll a3, a3, t6 # a3 *= 2
	li t6, 12 # restore for later
	add a3, a3, a7 # Imaginary part += c_imaginary
	sra a3, a3, t6 # Restore fixed point
	mul a1, a1, a1 # a1 = x^2
	mul a2, a2, a2 # a2 = y^2
	sub a1, a1, a2 # a1 -= y^2
	add a1, a1, a6 # a1 += c_real
	sra a1, a1, t6 # Restore fixed point
	mv a2, a3 # For next iteration
	
	
	
	mul a3, a1, a1 # a3 = new_real^2
	mul a4, a2, a2 # a4 = new_imaginary^2
	add t4, a3, a4 # t4 = |z|
	bltu t4, a0, iterate_fractal # if |z| < 4 iterate
	
store_byte:
	sb t3, 0(t0)
	sb t3, 1(t0)
	sb t3, 2(t0)
	addi t0, t0, 3
	blt t1, s3, loop_x
	
add_padding:
	beq s5, zero, increment_y # If no padding required jump to increment_y
	sb zero, 0(t0) # Add padding byte
	addi t0, t0, 1 # Increment buffer pointer
	addi t5, t5, 1 # Increment padding counter
	blt t5, s5 add_padding # Continue adding padding until padding counter reaches padding bytes number
increment_y:
	li t5, 0 # Restore padding counter
	li t1, 0 # Set x = 0
	addi t2, t2, 1 # y += 1
	blt t2, s4, loop_x # If y < height jump to loop_x
end:
	# Open file for writing
	li a7, 1024
	la a0, filename
	li a1, 1
	ecall
	# Wrtie to file
	li a7, 64
	mv a1, s1
	mv a2, s6
	ecall
	# Close the file
	li a7, 57
	mv a0, s2
	ecall
	# Exit
	li a7, 10
	ecall
	
store_4_bytes_little_endian:
	li t3, 8
	sb t0, 0(t2)
	
	mv t1, t0
	
	srl t1, t1, t3
	sb t1, 1(t2)
	
	srl t1, t1, t3
	sb t1, 2(t2)
	
	srl t1, t1, t3
	sb t1, 3(t2)
	
	ret		
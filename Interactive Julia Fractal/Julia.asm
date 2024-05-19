; https://www.ired.team/miscellaneous-reversing-forensics/windows-kernel-internals/windows-x64-calling-convention-stack-frame
; Microsoft x64 calling convention
; pixels (pointer to uint8_t) is accessed through the RCX
; width (integer) is accessed through the RDX
; height (integer) is accessed through the R8
; treshold (double) is accessed through the XMM3
; c_real, c_imag, centerX, centerY, and zoom (all doubles) are accessed through the stack [0x28] to [0x48]
; https://rosettacode.org/wiki/Julia_set#C - algortihm

    section .text
    global GenerateFractal

GenerateFractal:

	; Move dobules to certain registers to keep the order
    movsd xmm0, [rsp + 0x28]	; xmm0 = c_real
    movsd xmm1, [rsp + 0x30]	; xmm1 = c_imag
    movsd xmm2, [rsp + 0x38]	; xmm2 = centerX
    ; treshold in xmm3
    movsd xmm4, [rsp + 0x40]	; xmm4 = centerY
    movsd xmm5, [rsp + 0x48]	; xmm5 = zoom
	; uint8_t* pixels in rcx
	; width in rdx
	; height in r8
    mov r9, [rsp + 0x50]
    mov r10, [rsp + 0x58]
	; Prologue
	push	rbp
	mov		rbp, rsp
    ; r12 and r13 has to be preserved : https://www.cs.uaf.edu/2017/fall/cs301/reference/x86_64.html
    push r12
    push r13

    mov r12, r9
    mov r13, r10

    xor r9, r9 ; x = 0
    xor r10, r10 ; y = 0

loop_x:
    ; Fractal generation
	
    ; real part calculation

    cvtsi2sd xmm6, r9 ; real part = double(current x)

    subsd xmm6, xmm2 ; x -= centerX

    addsd xmm6, xmm6 ; x *= 2

    mulsd xmm6, xmm3 ; x *= treshold

    cvtsi2sd xmm7, rdx ; xmm7 = double(width)
    
    mulsd xmm7, xmm5 ; xmm7 = width * zoom

    divsd xmm6, xmm7 ; real part = (x - centerX) * 2 * treshold  / (width * zoom)

    ; imaginary part calculation

    cvtsi2sd xmm8, r10 ; imaginary part = double(current y)

    subsd xmm8, xmm4 ; y -= centerY

    addsd xmm8, xmm8 ; y *= 2

    mulsd xmm8, xmm3 ; y *= treshold

    cvtsi2sd xmm9, r8 ; xmm9 = double(height)
    
    mulsd xmm9, xmm5 ; xmm9 = height * zoom

    divsd xmm8, xmm9 ; imag part = (y - centerY) * treshold * 2 / (height * zoom)

    xor r11, r11 ; Iteration = 0

iterate_fractal:

    cmp r11, 255

    je store_byte

    inc r11 ; Iteration += 1

    ; New imaginary part calculation

    movsd xmm10, xmm6 ; xmm10 = real part

    mulsd xmm10, xmm8 ; xmm10 *= imaginary part

    addsd xmm10, xmm10     ; xmm10 *= 2 (xmm8 = 2ab)

    addsd xmm10, xmm1 ; xmm10 += c_imag

    ; New real part calculation

    movsd xmm11, xmm6 ; xmm11 = real part

    mulsd xmm11, xmm11 ; xmm11 = real part ^ 2

    movsd xmm12, xmm8 ; xmm12 = imaginary part

    mulsd xmm12, xmm12 ; xmm12 = imaginary part ^ 2

    subsd xmm11, xmm12 ; xmm11 -= new imaginary part ^ 2 (a^2 - b^2)

    addsd xmm11, xmm0 ;	xmm11 += c_real

    ;Save for next iteration

    movsd xmm6, xmm11 ; xmm6 = new real part

    movsd xmm8, xmm10 ; xmm8 = new imag part

	; |z|

    mulsd xmm10, xmm10 ; xmm10 = new imag part ^ 2

    mulsd xmm11, xmm11 ; xmm11 = new real part ^ 2

    addsd xmm10, xmm11 ; xmm10 = |z|

    comisd xmm10, xmm3 ; compare |z| with treshold

    jbe iterate_fractal ; if |z| <= treshold iterate

    inc r11 ; Increment iteration counter

store_byte:
    ; ARGB8888 format
    cmp r13b, 0
    je not_colored
    and r11, 31 ; calculate iteration % 32
    mov eax, [r12 + r11 * 4] ; Choose color
    mov dword [rcx], eax ; Store color at certain adress
    jmp byte_stored

not_colored:    ; If colored = false
    mov byte [rcx], r11b
    mov byte [rcx + 1], r11b
    mov byte [rcx + 2], r11b
    mov byte [rcx + 3], 255

byte_stored

    add rcx, 4 ; point to next pixel

	inc r9 ; X += 1

    cmp r9, rdx ; compare X with width

    jl loop_x ; If x < width: iterate

increment_y:
    inc r10 ; Increment y
    xor r9, r9 ; x = 0 (new line)
    cmp r10, r8 ; Compare y with height
    jl loop_x ; If y < height jump to loop_x

end:
    ; Epilogue
    pop r13
    pop r12
    mov rsp, rbp 
    pop rbp 
    ret
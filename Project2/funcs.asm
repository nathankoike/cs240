
TITLE funcs

; funcs.asm
; Nate Koike
; Spring 2019

; This is a set of functions

INCLUDE CS240.inc
.8086

.data
stringy	BYTE	"Uh-Oh_Spaghetti-O's.asm", 0

.code
; this function computes a(x^2) + bx + c
Polynomial PROC
	   push DS
	   pushf

	   ; get a(x^2)
	   ; DX gets consumed in multiplication, so preserve it
	   push DX
	   mul  DX
	   pop  DX

	   push DX
	   mul  DX
	   pop  DX

	   ; save CX, the save AX in CX
	   push CX
	   mov  CX, AX

	   ; move BX into AX to find bx
	   mov AX, BX

	   ; find bx
	   push DX
	   mul DX
	   pop DX

	   ; add in a(x^2)
	   add  AX, CX

	   ; restore CX
	   pop  CX

	   ; finally, add c
	   add  AX, CX

	   popf
	   pop  DS
	   ret
Polynomial ENDP

; find the factorial of a number in AX
Factorial PROC
	  push CX
	  pushf

	  ; check the zero case
	  cmp AX, 1
	  jb  zero

	  ; set the counter for factorial
	  mov  CX, AX

	  ; set the base value. this is either the return value or
	  ; will be multiplied to be the correct number
	  mov  AX, 1

start:
	  push DX
	  mul  CX
	  pop  DX
	  jc   overflow
	  loop start

done:
	  popf
	  pop  CX

	  ; reset the overflow flag
	  push AX
	  mov  AL, 1
	  add  AL, 1
	  pop  AX

	  ret

zero:
	  mov  AX, 1
	  jmp  done

overflow:
	  pop  CX
	  OR   CX, 0800h

	  push CX
	  popf

	  pop  CX

	  ret

Factorial ENDP

; this function computes the nth Fibonacci number
Fibonacci PROC
	  push BX
	  push CX
	  push DX
	  pushf

	  ; check the zero case
	  cmp  AX, 1
	  jb   done

	  ; make a counter
	  mov  CX, AX

	  ; set the 0th and 1st Fibonacci numbers
	  mov  AX, 0
	  mov  DX, 1

start:
	  ; save the last value in BX
	  mov  BX, AX

	  ; find the current value
	  add  AX, DX

	  ; move the last value to DX
	  mov  DX, BX

	  loop start

done:
	  popf
	  pop  DX
	  pop  CX
	  pop  BX
	  ret

Fibonacci ENDP

; this is a helper function that writes a single char
; to the screen
PrintChar PROC
	; assume that the character to write has already
	; been placed in DL
	push	AX

	mov	AH, 02h	; this is the DOS code to write a char
	int	21h	; call DOS to write the character

	pop	AX
	ret

PrintChar ENDP

; this function writes a string starting from the OFFSET
; stored in DX
PrintString PROC
	push	BX
	push	DX
	pushf

	; put the address into BX
	mov	BX, DX

print:
	; put the next char in DL and print it
	mov	DL, [BX]
	cmp	DL, 0
	je	done
	call	PrintChar
	inc	BX	; increment BX to the next position
	jmp	print

done:
	popf
	pop	DX
	pop	BX
	ret
PrintString ENDP

; this writes the single hex digit in DL to the screen
PrintHexDigit PROC
	push	DX
	pushf

	; get just the last digit in DL
	AND	DL, 00001111b

	; find out which set of digits to print
	cmp	DL, 0Ah
	jl	decimal
	jmp	hex

decimal:
	add	DL, 48
	jmp	print

hex:
	add	DL, 55

print:
	call PrintChar

	popf
	pop DX
	ret
PrintHexDigit ENDP

END

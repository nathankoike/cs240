TITLE Project5

; Nate Koike
; project5.asm
; Spring 2019

.model small,stdcall
.stack 200h

.8086

.data
; this will print when SafeRead is terminated with ctrl-c
Closed  BYTE  "input cancelled.", 0

; this is used as a placeholder byte to make saving data easier
; simply put, this is here so i don't have to mess with the stack too much
Hold	BYTE	?

.code
; ==============================================================================
; ============================= OLD FUNCTIONS ==================================
; ==============================================================================

; write the character represented by the bits in DL to the screen
PrintChar PROC
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

; print a new line
LineBreak PROC
	push	DX
	; add a carriage return
	mov	DL, 13
	call	PrintChar
	; move the cursor to the line below
	mov DL, 10
	call	PrintChar
	pop	DX
	ret
LineBreak ENDP

; print a single space
PrintSpace PROC
	push	DX
	mov	DL, ' '
	call	PrintChar
	pop	DX
	ret
PrintSpace ENDP

; THIS FUNCTION HAS BEEN MODIFIED FROM ITS ORIGINAL FORM
; fill the buffer with all 0's
; the offset of the buffer is in BX
; the length of the buffer is in AX
ClearBuffer PROC
	push	DX
	push	SI
  pushf

  mov DX, 0
  mov SI, 0
top:
  cmp SI, AX
  je  done

  mov [BX + SI], DX

  inc SI
  jmp top
done:
  popf
	pop	SI
	pop DX
  ret
ClearBuffer ENDP

; THIS FUCTION HAS BEEN MODIFIED FROM ITS ORIGINAL FORM TO PRNINT LOWERCASE
; LETTERS INSTEAD OF UPPERCASE LETTERS FOR THE HEX DIGITS
; this writes the lower 4 bits in DL to the screen
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
	add	DL, 87
print:
	call PrintChar
	popf
	pop DX
	ret
PrintHexDigit ENDP

; write the whole byte in DL to the screen
PrintHexByte PROC
	push	DX
	pushf
	push	DX
	push	CX
	; set CL to use in the shift instruction
	mov	CL, 4
	; move the higher 4 bits into the lower 4 bits to get them to print
	SHR	DX, CL
	call PrintHexDigit
	pop	CX
	pop	DX
	call PrintHexDigit
	popf
	pop	DX
	ret
PrintHexByte ENDP

; this function writes AX to the screen as a hex word
PrintHexWord PROC
	push	DX

	mov	DL, AH
	call	PrintHexByte

	mov	DL, AL
	call	PrintHexByte

	pop	DX
	ret
PrintHexWord ENDP

; ==============================================================================
; ==================== NEW FUNCTIONS BELOW THIS LINE ===========================
; ==============================================================================

; this reads a single character from the standard input
; wipes DX and returns the character in DL
ReadChar PROC
	push	AX

	mov	AX, 0700h
	int	21h

	mov	DL, AL

	pop	AX
	ret
ReadChar ENDP

; handle the backspace character properly
; decrement SI to make room for more characters
Backspace PROC
	pushf

	; check to make sure we aren't writing below what we should be able to
	cmp	SI, 0
	je done

	push	DX

	; decrenemt SI so we are at the correct index
	dec	SI

	; move the backspace character into DL and print it
	; this moves the cursor back one space
	mov	DL, 08h
	call	PrintChar

	; this erases the previous character
	call	PrintSpace

	; move the cursor back one space to receive more input
	mov	DL, 08h
	call	PrintChar

	; now, reset the value in the buffer to be 0
	mov	DX, 0
	mov	[BX + SI], DX

	pop	DX ; restore the value of DX
done:
	popf
	ret
Backspace ENDP

; read in characters from the user and store them into a buffer
SafeRead PROC
	push	AX				;			+0
	push	BX				;			+2
	push	BP				;			+4
	push	SI				;			+6
	pushf						;			+8
	; return address			+10

  ; get the offset of the buffer from the stack and put it into BX
	mov	BP, SP	; get the address of the top of the stack in BP
	mov	BX, [BP + 14] ; this is the address of the offset in the stack

	; set the offset from the beginning of the buffer
	mov	SI, 0

  ; get the length of the buffer and put it into AX
	mov	AX, [BP + 12] ; this is the address of the length of the buffer

	; this gets rid of the null termination from the set of bytes we can address
	dec	AX

	; fill the buffer with all 0's so we can properly make a
	; null-terminated string
	call	ClearBuffer
top:
  ; read in a character
	call ReadChar

  ; check to see if the character is either a carriage return or ctrl-c
  ; if the character is ctrl-c, exit the program abruptly with a message
  ; if the character is a carriage return, end the program gracefully
	; backspace is also a special case, so check that too

	; check for ctrl-c
	cmp	DL, 03h
	je	ctrlc

	; check for a new line
	cmp	DL, 13
	je	newline

	; check for the backspace character
	cmp	DL, 8
	je	back
write:
	; check to see if we have room left to write characters
	cmp	SI, AX
	je	top

	mov	[BX + SI], DL

	call	PrintChar

	inc	SI
	jmp	top
back:
	call	backspace
	jmp	top
ctrlc:
	call	LineBreak
	mov	DX, OFFSET Closed
	call	PrintString
	call	LineBreak

	; abort DOS
	mov	AX, 4C00h
	int	21h
newline:
	call LineBreak
	jmp	done
done:
	popf
	pop	SI
	pop	BP
	pop	BX
	pop	AX
  ret
SafeRead ENDP

; convert ms to seconds and 5/100ths of a second
; number of ms to convert is in AX
; returns ss.ss in AX
; return the number of minutes in CL
GetSeconds PROC
	push	DX
	push	CX
	pushf
; this gets the number of seconds to delay in 1/100ths of a second
; this number is still 5x more accurate than the system clock but we will
; account for this later
toHundredths:
	mov	DX, 0
	mov	CX, 10

	div	CX
; this properly converts the number of 1/100ths of a second into seconds and
; 1/100ths of a second
toSeconds:
	mov	CX, 100
	mov	DX, 0
	div	CX

	; save the 1/100ths, move the seconds to the right spot, move the 1/100ths
	; to the right spot
	mov	CL, DL
	mov	AH, AL
	mov	AL, CL
; now, we account for the 1/100ths of a second being 5x more accurate than the
; system clock
accuracy:
	push	AX
	mov	Cl, 5
	mov	AH, 0
	div	CL

	; save the remainder, restore the original value, and subtract the remainder
	mov	CL, AH
	pop	AX
	sub	AL, CL
done:
	popf
	pop	CX
	pop	DX
	ret
GetSeconds ENDP

; convert seconds to minutes
; the number of seconds is in BH
; return the number of minutes in AL
GetMins PROC
	push	CX

	mov	CL, 60
	mov AX, 0
	mov	AL, BH

	div	CL

	; move the remainder of the seconds into the seconds
	mov	BH, AH

	pop	CX

	; there will never be any hours, so set that value to 0
	mov	AH, 0

	ret
GetMins ENDP

; convert milliseconds to hh:mm:ss.ss
; time format
; hh:mm  	ss.ss
; AH:AL   BH:BL
; the number of milliseconds to delay is in AX
GetDelay PROC
	push	CX

	call	GetSeconds
	mov	BX, AX

	call	GetMins

	pop	CX
	ret
GetDelay ENDP

; get the final amount of seconds in BX
; the number of seconds to add is in BX
; the starting number of seconds is in DX
; the final number of seconds is in BX with the carry added to AL
GetFinalSec PROC
	push	CX
	push	DX

	; get the sum final number of seconds in BX
	add	BX, DX
hundredths:
	; prep for division
	push	AX

	mov	AX, BX
	mov	CL, 100
	mov	AH, 0

	; divide the 1/100ths value
	div	CL

	; this is the final value of the 1/100ths value
	mov	BL, AH

	; this is the carry into the seconds place
	add	BH, AL

	; restore the value of AX
	pop	AX
seconds:
	; prepare to shift
	push	AX

	mov	AX, BX
	mov	CL, 8

	; move AH into AL
	shr	AX, CL

	; prep for division
	mov	CL, 60

	; divide the seconds value
	mov	AH, 0
	div	CL

	; this is the final value of the seconds value
	mov	BH, AH

	; store the carry value from seconds into minutes
	mov	CL, AL

	; restore the value of AX
	pop	AX

	; this is the carry into the seconds place
	add	AL, CL
done:
	pop	DX
	pop	CX
	ret
GetFinalSec ENDP

; get the final amount of hours and minutes in AX
; the number of hours and minutes to add is in AX
; the starting number of hours and minutes is in CX
GetFinalHrMin PROC
	push	DX

	; get the sum of the final number of hours and minutes
	add	AH, CH
	add	AL, CL
minutes:
	; prepare to divide
	push	AX
	mov	DL,	60
	mov	AH, 0

	div	DL

	; the number of hours previously stored in the minutes of AL is now in AL
	; the number of minutes remaning should be in AH
	mov	DL, AH
	mov	DH, AL

	; restore AX
	pop	AX

	; DX now has the proper format for AX, but it hasn't added the carry hour
	mov	AL, DL
	add	AH, DH
; the time is reported in 24 hour mode, so account for that here
hours:
	push	AX

	; prepare to shift
	push	CX
	mov	CL, 8

	; move AH into AL
	shr	AX, CL

	; restore the value of CX
	pop	CX

	; prepare to divide
	mov	DL, 24
	mov	AH, 0

	div	DL

	; the remainder will be the number of hours at the end, so that's what
	; we care about here
	mov	DH, AH

	; restore the value of AX
	pop	AX

	; now move the number of hours back into AH
	mov	AH, DH
done:
	pop	DX
	ret
GetFinalHrMin ENDP

; get the system time in CX and DX
GetSysTime PROC
	push	AX
	push	BX

	mov	AX, 2C00h
	int	21h

	pop	BX
	pop	AX
	ret
GetSysTime ENDP

; this finds the final system time at the end of the delay
; its parameters for the time to delay are as follows
; hh:mm  	ss.ss
; AH:AL   BH:BL
; its return takes the exact same shape
GetFinalTime PROC
	call	GetSysTime
	call	GetFinalSec
	call	GetFinalHrMin
	ret
GetFinalTime ENDP

; delay for some number of milliseconds. this number is found on the stack
Delay PROC
	push	AX				;			+0
	push	BX				;			+2
	push	CX				;			+4
	push	DX				;			+6
	push	BP				;			+8
	pushf						;			+10
	; return address			+12

	mov	BP, SP

	; move the number of milliseconds to delay into AX
	mov	AX, [BP + 14]

	; see if the number of milliseconds to delay is less than the number needed
	; to round up to 5/100 of a second (the unit reported by the machine)
	cmp	AX, 50
	jb	done

	; time format
	; hh:mm  	ss.ss
	; AH:AL   BH:BL
	call	GetDelay

	; this gets the final system time for comparison
	; time format
	; hh:mm  	ss.ss
	; AH:AL   BH:BL
	call	GetFinalTime

top:
	call	GetSysTime

	cmp	AX, CX
	ja	top

	cmp	BX, DX
	jb	done

	jmp	top

done:
	popf					;			+10
	pop	BP				;			+8
	pop	DX				;			+6
	pop	CX				;			+4
	pop	BX				;			+2
	pop	AX				;			+0
	ret
Delay ENDP
END

TITLE hexdump

; Nate Koike
; hexdump.asm
; Spring 2019

include CS240.inc
.8086

CMDTAIL = 6200h
INPUTCMD = 81h
OPENFILE = 3D00h
READFILE = 3F00h
EXITDOS = 4C00h
DOS = 21h

; Typical output
; hhhhhhhh  hh hh hh hh hh hh hh hh  hh hh hh hh hh hh hh hh  |cccccccccccccccc|
; number of chars printed in hex   hex value of each char   human-readable chars

.data
; this will be used to print the human-readable characters
Human BYTE  '|'

; it is important that this is null terminated because the ending needs to be
; manually printed in case the buffer cannot be filled completely and the
; function used to print strings terminates earlier than anticipated
HBuffer  BYTE  ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0

HEnd  BYTE  '|', 0

; these two buffers are used to accept input from the file
; Buff1 is the last 16 bytes read and will be used for comparison
; Buff2 is the current 16 bytes and will be compared to Buff1
Buff1  BYTE  ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0
Buff2  BYTE  ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0

; this is the carry used to hold the final hex digits to be printed in the
; left-most section of the output
HexC	WORD 0

; this tracks whether the last output was a repeat or a full line
Repeated BYTE 0

OpenError	BYTE	"Error opening file.", 0

ReadError	BYTE	"Error reading from file.", 0

; this is the filename
FName	BYTE	?

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

; write a string of hex digits without spaces starting from the address in BX
; and printing a number of values equal to the number stored in CX
PrintHexString PROC
	push	BX
	push	CX
	push	DX
	pushf
compare:
	cmp	CX, 0
	je	done
start:
	mov	DL, [BX]
	call PrintHexDigit
	inc	BX
	dec	CX
	jmp	compare
done:
	popf
	pop	DX
	pop	CX
	pop	BX
	ret
PrintHexString ENDP

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

; this function fills the buffer with all zeroes to be overwritten so that the
; function only prints as many chars as necessary
ClearBuffer PROC
  push  AX
  push  BX
	push	SI
  pushf

  mov AX, 0
  mov SI, 0
  mov BX, OFFSET HBuffer
top:
  cmp SI, 16
  je  done

  mov [BX + SI], AX

  inc SI
  jmp top
done:
  popf
	pop	SI
  pop BX
  pop AX
  ret
ClearBuffer ENDP

; fill the human-readable buffer with readable characters from Buff2
FillBuffer PROC
	push  AX
	push  BX
	push	DX
	push	SI
	pushf

	; we need to clear the buffer before we can fill it
	call	ClearBuffer

	mov AX, OFFSET HBuffer
	mov SI, 0
	mov BX, OFFSET Buff2
top:
  cmp SI, 16
  je  done

  mov DL, [BX + SI]	; BX is Buff2

	cmp	DL, ' '
	jb	unprintable

	cmp	DL, '~'
	ja	unprintable
fill:
	XCHG	AX, BX	; BX is now HBuffer

	mov	[BX + SI], DL

	XCHG	BX, AX	; BX is Buff2 again

  inc SI
  jmp top
unprintable:
	mov	DL, '.'
	jmp fill
done:
  popf
	pop	SI
	pop	DX
  pop BX
  pop AX

	ret
FillBuffer ENDP

; print the human readable section of the output
PrintHumanReadable PROC
  push  DX

  mov DX, OFFSET Human
  call PrintString

  mov DX, OFFSET HEnd
  call  PrintString

  pop DX
  ret
PrintHumanReadable ENDP

; this function increments the count of how many characters have been seen so
; far. it takes a byte in memory and DX as its parameters
IncCount PROC
	pushf

	; clear the carry flag to check if CX has looped back to 0
	CLC

	add	DX, BX

	; if there was not a carry we are done
	jnc done

	INC	HexC
done:
	popf
	ret
IncCount ENDP

; this function prints the left-most section of the output: the number of chars
; seen by the program. it takes 1 byte in memory to use as the 2 most
; significant hex digits and DX
PrintCount PROC
	push	AX
	push	DX

	; print the most significant digits
	push	DX
	mov	AX, HexC
	call	PrintHexWord
	pop	DX

	; print the value of DX
	mov	AX, DX
	call	PrintHexWord

	pop	DX
	pop	AX
	ret
PrintCount ENDP

; if there is a repeated set of 16 just call this instead
PrintRepeat PROC
	push	DX
	pushf

	; see if the last character was denoted a repeated line
	cmp	Repeated, 0FFh
	je	done

	mov	DL, '*'

	call	PrintChar

	; print a new line
	call	LineBreak

	; note that the last output was a repeat symbol
	mov	Repeated, 0FFh
done:
	popf
	pop	DX

	ret
PrintRepeat ENDP

; print a single space
PrintSpace PROC
	push	DX
	mov	DL, ' '
	call	PrintChar
	pop	DX
	ret
PrintSpace ENDP

; this function prints 16 bytes as hex digits with proper formatting
PrintHexLine PROC
	push	BX
	push	DX
	push	SI
	pushf

	; queue the most recent set of characters to be printed
	mov	BX, OFFSET Buff2

	; reset the counter for the number of things to print
	mov	SI, 0
first:
	cmp SI, 8
	je	second

	mov	DL, [BX + SI]

	call PrintHexByte
	call PrintSpace

	INC	SI
	jmp first
second:
	cmp	SI, 16
	je	done
	mov	DL, [BX + SI]

	call PrintSpace
	call PrintHexByte

	INC	SI
	jmp second
done:
	popf
	pop	SI
	pop	DX
	pop	BX
	ret
PrintHexLine ENDP

; compare Buff1 and Buff2 then return whether or not they are equal
; set CF if they are equal, clear it otherwise
CompareBuffer PROC
	push	AX
	push	BX
	push	DX
	push	SI

	; this is the last set of 16 characters we read in
	mov	AX, OFFSET Buff1

	; this is the buffer we need to switch to be the last thing we read in
	mov	BX, OFFSET Buff2

	; this is the counter for the number of bytes swapped
	mov	SI, 0
top:
	cmp SI, 16
	je  Equal
switch:
	; DX is now holds the value in Buff2
	mov DL, [BX + SI]

	; switch to addressing Buff1
	XCHG	AX, BX

	; compare the value in the same location in Buff1 with the value in Buff2
	cmp	[BX + SI], DL
	jne NotEqual

	; switch the buffers back
	XCHG	AX, BX

	inc SI
	jmp top
NotEqual:
	XCHG	AX, BX
	CLC
	jmp done
Equal:
	STC
done:
	pop	SI
	pop	DX
	pop	BX
	pop	AX
	ret
CompareBuffer ENDP

; move the contents from Buff2 into Buff1
SwitchBuffer PROC
	push	AX
	push	BX
	push	DX
	push	SI
	pushf

	; this is the last set of 16 characters we read in
	mov	AX, OFFSET Buff1

	; this is the buffer we need to switch to be the last thing we read in
	mov	BX, OFFSET Buff2

	; this is the counter for the number of bytes swapped
	mov	SI, 0
top:
  cmp SI, 16
  je  done
switch:
	; DX is just a temporary variable here
  mov DL, [BX + SI]

	; switch the offset of the buffer being used
	XCHG	AX, BX

	mov	[BX + SI], DL

	; switch the buffers back
	XCHG	BX, AX

  inc SI
  jmp top
done:
	popf
	pop	SI
	pop	DX
	pop	BX
	pop	AX
	ret
SwitchBuffer ENDP

; this prints a line of normal output
PrintLine PROC
	call PrintCount

	call PrintSpace
	call PrintSpace

	call PrintHexLine

	call PrintSpace
	call PrintSpace

	call PrintHumanReadable

	call LineBreak

	; make sure the program knows that we didn't print a repeat line last
	mov	Repeated, 0

	ret
PrintLine ENDP

; prints a short hex line
; the number of bytes to print is in BX
; the file handle is in AX
; the file offset is in DX
PrintShortHex PROC
	push	AX
	push	BX
	push	DX
	push	SI
	pushf

	; move the number of bytes to print into AX
	mov	AX, BX

	; get the offset to start reading from
	mov	BX, OFFSET Buff2

	; get the starting offset for the number of characters
	mov	SI, 0
top:
	cmp	SI, AX
	je	done

	mov	DL, [BX + SI]
	call	PrintHexByte
	call	PrintSpace

	cmp	SI, 7
	je	space
back:
	inc	SI
	jmp	top
space:
	call	PrintSpace
	jmp	back
done:
	popf
	pop	SI
	pop	DX
	pop	BX
	pop	AX
	ret
PrintShortHex ENDP

; prints the proper number of spaces at the end of a short hex line
; the number of bytes printed is in BX
; the file handle is in AX
; the file offset is in DX
SpaceOut PROC
	push	AX
	pushf

	; start by getting the worst case scenario
	mov	AX, 16

	; find the actual number of space bytes we need to print
	sub	AX, BX

	cmp	AX, 7
	jb	top

	call	PrintSpace
top:
	cmp	AX, 0
	je done

	call	PrintSpace
	call	PrintSpace
	call	PrintSpace

	dec	AX
	jmp	top
done:
	popf
	pop	AX
	ret
SpaceOut ENDP

; the number of bytes printed is in BX
; the file handle is in AX
; the file offset is in DX
FillEnding PROC
	push	AX
	push	BX
	push	CX
	push	DX
	push	SI
	pushf

	call	ClearBuffer

	; save the number of bytes to print
	mov	AX, BX

	; get the offset of the buffer we need to read from
	mov	BX, OFFSET Buff2

	; get the offset of the buffer we need to write to
	mov	CX, OFFSET HBuffer

	; get the starting offset
	mov	SI, 0
top:
  cmp SI, AX
  je  done

  mov DL, [BX + SI]	; BX is Buff2

	cmp	DL, ' '
	jb	unprintable

	cmp	DL, '~'
	ja	unprintable
fill:
	XCHG	CX, BX	; BX is now HBuffer

	mov	[BX + SI], DL

	XCHG	BX, CX	; BX is Buff2 again

  inc SI
  jmp top
unprintable:
	mov	DL, '.'
	jmp fill
done:
	popf
	pop	SI
	pop	DX
	pop	CX
	pop	BX
	pop	AX
	ret
FillEnding ENDP

; this fucntion prints the proper output for a line with fewer than 16 hex chars
PrintShortLine PROC
	push	BX
	push	DX
	push	SI
	pushf

	call	PrintCount

	call	PrintSpace
	call	PrintSpace

	call	PrintShortHex
	call	SpaceOut
hread:
	call	PrintSpace

	call	FillEnding
	call	PrintHumanReadable
done:
	call	LineBreak

	popf
	pop	SI
	pop	DX
	pop	BX
	ret
PrintShortLine ENDP

; this gets the file name from the command line
GetFileName PROC
	push	AX
	push	BX
	push	SI
	pushf

	; get a pointer to the command tail in BX
	mov	AX, CMDTAIL
	int	DOS

	; this is for indexing the command tail
	mov SI, INPUTCMD

	; move the offset of the filename into BX
	mov	BX, OFFSET FName
; cleans out unreadable characters from the command line
clean:
	inc	SI

	; ES is needed here to read from the command line instead of from DS
	mov	AL, ES:[SI]

	cmp	AL, ' '
	jbe clean

	cmp	AL, '~'
	ja	clean
; grabs the file name
top:
	mov	[BX], AL

	inc	SI

	; ES is needed here to read from the command line instead of from DS
	mov	AL, ES:[SI]

	cmp	AL, ' '
	jbe done

	cmp	AL, '~'
	ja	done

	inc	BX

	jmp top
done:
	; null terminate the string
	inc BX

	push	AX
	mov	AX, 0
	mov	[BX], AX
	pop	AX

	; pop and return
	popf
	pop	SI
	pop	BX
	pop	AX
	ret
GetFileName ENDP

; this gets input from the file
; it takes the number of characters to read in CX
; it returns the number of characters it read in BX
GetInput PROC
	push	AX
	push	DX

	; move the file handle into the proper place
	mov	BX, AX

	; move provide the place to store all the input from the file in DX
	mov	DX, OFFSET Buff2

	; provide the proper DOS interrupt in AX
	mov	AX, READFILE
	int	DOS

	; save the number of characters read from the file
	mov	BX, AX

	pop	DX
	pop	AX
	ret
GetInput ENDP

; this is in charge of outputting the correct line to the screen
; any errors in reading the file are handled here
; AX has the file handle
Output PROC
	push	CX
	push	DX
	pushf

	; get the starting file offset
	mov	DX, 0

	; this is the number of characters to read in
	mov	CX, 16

; this is just the first line of output
first:
	CLC
	call	GetInput
	jc	Error

	call	FillBuffer

	cmp	BX, 0
	je	empty

	cmp	BX, CX
	jne	ending

	call	PrintLine
	call	IncCount
	call	SwitchBuffer

; this is the loop that goes through the whole file
top:
	CLC
	call	GetInput
	jc	Error

	call	FillBuffer

	; see if 0 characters were read in
	cmp	BX, 0
	je	done

	; see if there were fewer than 16 characters read in
	cmp	BX, CX
	jne	ending

	; check to see if we need to output a star
	call	CompareBuffer
	jc	star

	call	PrintLine
	call	IncCount

	call	SwitchBuffer

	jmp	top
ending:
	call	PrintShortLine
	call	IncCount
	jmp	done
star:
	call	PrintRepeat
	call	IncCount
	call	SwitchBuffer
	jmp	top
Error:
	mov	DX, OFFSET ReadError
	call	PrintString
done:
	call	PrintCount
	call	LineBreak
empty:
	popf
	pop	DX
	pop	CX
	ret
Output ENDP

; this returns the file handle in AX or sets the carry flag if there is an error
GetHandle PROC
	push	DX
	; move the filename into DX
	mov	DX, OFFSET FName

	; attempt to open the file
	mov	AX, OPENFILE
	int DOS

	; see if there was an error
	jnc	done

	; this sets the carry flag
	STC
done:
	pop	DX
	ret
GetHandle ENDP

; ==============================================================================
; ================================== MAIN ======================================
; ==============================================================================

main PROC
  mov AX, @data
  mov DS, AX

	; get the filename from the command line
  call	GetFileName

	; Clear CF because this will signal all errors
	CLC

	; get the file handle to access the file
	call	GetHandle

	; check if there was an error
	jc Error

	; any errors from here until the end of the program will be handled by Output
	; currently AX has the file handle and nothing else is stored
	call	Output
	jmp	done

Error:
	; print the file open error
	mov	DX, OFFSET OpenError
	call	PrintString
	call	LineBreak

done:
  mov AX, EXITDOS
  int DOS
main ENDP
END main

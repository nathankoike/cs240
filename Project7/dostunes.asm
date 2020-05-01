; INCLUDE cs240.inc
; INCLUDE lablib.inc

.model small, stdcall
.stack 400h

.386

CMDTAIL = 6200h
INPUTCMD = 81h
OPENFILE = 3D00h
READFILE = 3F00h
EXITDOS = 4C00h
DOS = 21h

TIMER_DATA_PORT		= 42h
TIMER_CONTROL_PORT	= 43h
SPEAKER_PORT		= 61h
READY_TIMER		= 0B6h

; tune this for desktop
CPU_CLOCK = 1196000 ; this goes in AX. in DX put 12h

; tune this for laptop
;CPU_CLOCK = 1190500 ; this goes in AX. in DX put 12h

.data
; CITE: Professor Bailey
; DESC: Convinced me to use a more musician-friendly parsing scheme
; 			this parsing scheme is in the following 3 arrays

; express all the notes as the base note and the sharp variant
NotS WORD "C ", "C#", "D ", "D#", "E ", "F ", "F#", "G ", "G#", "A ", "A#", "B "
	   WORD 0	; this ends the notes

; express all the notes as the base note and the flat variant
NotF WORD "C ", "Db", "D ", "Eb", "E ", "F ", "Gb", "G ", "Ab", "A ", "Bb", "B "
	   WORD 0	; this ends the notes

; express all the notes as the frequency they correspond with in the 4th octave
Fre4 WORD 0262, 0277, 0294, 0311, 0330, 0349, 0370, 0392, 0415, 0440, 0466, 0494



; this buffer is used to accept input from the file
Buffer  BYTE  ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0

; this is the filename
FName	BYTE	?

.code

; ==============================================================================
; ============================= OLD FUNCTIONS ==================================
; ==============================================================================

; FUNCTIONS FROM PROJECT4

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

; this function writes a string starting from the OFFSET stored in DX
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

; this gets the file name from the command line
GetFileName PROC
	push	AX
	push	BX
	push	SI
	push	ES
	pushf

	; get a pointer to the command tail in BX
	mov	AX, CMDTAIL
	int	DOS

	mov	ES, BX

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
	pop	ES
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
	mov	DX, OFFSET Buffer

	; provide the proper DOS interrupt in AX
	mov	AX, READFILE
	int	DOS

	; save the number of characters read from the file
	mov	BX, AX

	pop	DX
	pop	AX
	ret
GetInput ENDP

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



; FUNCTIONS FROM PROJECT5

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



; from a homework assignment

; multiply AX by 10
timesTen	PROC
	push	BX
	push	CX
	push	DX

	; DX = AX * 2
	mov	DX, AX
	shl	DX, 1

	; AX *= 8
	mov	CL, 3
	shl	AX, CL

	; 8AX + 2AX = 10AX
	add	AX, DX

	pop	DX
	pop	CX
	pop	BX
	ret	; AX is now 10x its original value
timesTen	ENDP

; ==============================================================================
; ==================== NEW FUNCTIONS BELOW THIS LINE ===========================
; ==============================================================================

; CITE: Professor Bailey
; DESC: Provided this code on Piazza to turn the speaker on
SpeakerOn PROC
	pushf
	push	ax

	in	al, SPEAKER_PORT		; Read the speaker register
	or	al, 03h				; Set the two low bits high
	out	SPEAKER_PORT, al		; Write the speaker register
done:
	pop	ax
	popf
	ret
SpeakerOn ENDP

; CITE: Professor Bailey
; DESC: Provided this code on Piazza to turn the speaker off
SpeakerOff PROC
	pushf
	push	ax

	in	al, SPEAKER_PORT		; Read the speaker register
	and	al, 0FCh			; Clear the two low bits high
	out	SPEAKER_PORT, al		; Write the speaker register

	pop	ax
	popf
	ret
SpeakerOff ENDP

; CITE: Professor Bailey
; DESC: Provided a call to this function in the skeleton program provided on
; 			Piazza
; take the frequency in BX and return a timer count in DX
NoteFrequencyToTimerCount	PROC
	push	EAX
	push	EBX

	mov	EAX, CPU_CLOCK
	; CITE: Eliza
	; DESC: on the Monday when Professor Bailey wasn't here and we were to work on
	;       out project, Eliza and I tuned the CPU speaker. This was her idea
	mov	DX, 12h

	; we never need to use EBX becasue the highest frequency in normal range of
	; human hearing is 20kHz, well below the maximum 65535Hz allowed in BX
	div	BX

	; move the timer count into DX. this will never be larger than 65535
	mov	DX, AX

	pop	EBX
	pop	EAX
	ret
NoteFrequencyToTimerCount	ENDP

; CITE: Professor Bailey
; DESC: Provided this code on Piazza to play a frequency through the CPU speaker
PlayFrequency PROC
	; I made an edit here to change the frequency to be found in BX instead of DX
	;; Frequency is found in BX

	pushf
	push	ax

	call	NoteFrequencyToTimerCount

	mov	al, READY_TIMER			; Get the timer ready
	out	TIMER_CONTROL_PORT, al

	mov	al, dl
	out	TIMER_DATA_PORT, al		; Send the count low byte

	mov	al, dh
	out	TIMER_DATA_PORT, al		; Send the count high byte

	call	SpeakerOn

	; there were more lines of code here to do things like play the note for a
	; specified amount of time and to add a delay between notes but i removed
	; those to handle them elsewhere

	pop	ax
	popf
	ret
PlayFrequency ENDP

; this function plays a note for a specified amount of time
; this is where i moved handling the timing of notes
; the time of the note in ms is in CX and the note frequency in Hz is in EBX
PlayNote	PROC
	push	EAX
	push	EDX
	pushf

	mov	EAX, 0
	mov	EDX, 0
	push	CX	; delay works woth the stack so we need to push
	call	PlayFrequency
	call 	Delay
	pop	CX	; make sure to pop off of the stack so we can return

	popf
	pop	EDX
	pop	EAX
	ret
PlayNote	ENDP

; remove all the non-numeric characters from a file and return the first
; numeric character in DL
CleanFile	PROC
	push	AX
	push	BX
	push	CX
	pushf

top:
	mov	CX, 1
	call	GetInput

	; check to see if we reached the end of the file
	cmp	BX, 1
	jne	done

	mov	BX, OFFSET Buffer
	mov	DL, [BX]

	; filter out any non-numerical values
	cmp	DL, '0'
	jb	top
	cmp	DL, '9'
	ja	top

done:
	popf
	pop	CX
	pop	BX
	pop	AX
	ret
CleanFile	ENDP

; get the decimal number from a file into DX
; set the carry flag if we have reached the end of the file
LoadDecimal	PROC
	push	AX
	push	BX
	push	CX
	pushf

	mov	DX, 0	; clear DX
	mov	CX, 0	; clear CX

	call	CleanFile	; add the first numeric character to DX

number:
	;	get the next character
	mov	CX, 1
	call	GetInput

	; check to see if we reached the end of the file
	cmp	BX, 1
	jne	ending

	; check to see if the character is non-numeric
	mov	BX, OFFSET Buffer
	mov	CL, [BX]

	cmp	CL, '0'
	jb	done

	cmp	CL, '9'
	ja	done

	; at this point we know that there is another number
	; get the numeric value represented by the last character in DX
	sub	DX, '0'

	; multiply DX by 10
	push	AX
	mov	AX, DX
	call	timesTen
	mov	DX, AX
	pop	AX

	; add the next number to DX
	add	DX, CX

	jmp	number	; loop

ending:
	; this is if we have reached the end of the file
	popf
	STC
	pushf
	add	DX, '0'	; just prevent the program from trying to divide by 0
	add	DX, 10

done:
	; get the numeric value represented by the last character in DX
	sub	DX, '0'

	popf
	pop	CX
	pop	BX
	pop	AX
	ret
LoadDecimal	ENDP


; ; load a note and change its octave if necessary
; LoadNote	PROC
; 	push	AX
; 	push	BX
; 	push	CX
; 	push	SI
; 	pushf
;
; 	mov	DX, 0	; clear DX
; 	mov	CX, 0	; clear CX
; 	mov	SI, 0	; clear SI
;
; note:
; 	;	get the next character
; 	mov	CX, 2
; 	call	GetInput
;
; 	; check to see if we reached the end of the file
; 	cmp	BX, 2
; 	jne	ending
;
; 	; check to see if the character is a note
; 	mov	BX, OFFSET Buffer
; 	mov	AX, [BX]
;
; sharps:
; 	; we now have the note, do let's find the frequency of the note in octave 4
; 	mov	BX, OFFSET NotS
; 	mov	CX, [BX + SI]
;
; 	cmp	CX, 0
; 	je	flats
;
; 	cmp	CX, AX
; 	je fill
;
; 	add	SI, 2
; 	jmp	sharps
;
; flats:
; 	; the note must be flat then
; 	; we need to clear SI again
; 	mov	 SI, 0
;
; 	mov	BX, OFFSET NotF
; 	mov	CX, [BX + SI]
;
; 	cmp	CX, AX
; 	je fill
;
; 	cmp	CX, 0
; 	je	ending
;
; 	add	SI, 2
; 	jmp	flats
;
; fill:
; 	; move the frequency into DX
; 	mov	BX, OFFSET Fre4
; 	mov	DX, [BX + SI]
;
; octave:
; 	; change the octave of the note we just loaded
; 	mov	BX, DX	; save the frequency of the note
;
; 	call	LoadDecimal	; load the octave number into DX
;
; 	; get the octave difference
; 	mov	CX, 4
; 	mov	dx, 3	; test code
; 	sub	CX, DX
;
; 	cmp	CX, 0080h	; check to see if we neet to perform 2's complement
; 	jb	shiftOct
;
; 	; this code was copied from Project3
; 	NOT	CX	; flip all the bits of AX and ...
; 	inc	CX	; ... add 1 to AX, thus completing 2's complement
;
; 	; the desired octave is higher, so we need to shift the frequency up
; 	shl	BX, CL
;
; 	mov	DX, BX	; relocate the return value properly
;
; 	jmp	done
; shiftOct:
; 	; the desired octave is lower, so we need to shift the frequency down
; 	shr	BX, CL
;
; 	mov	DX, BX ; relocate the return value properly
;
; 	jmp	done
;
; ending:
; 	; this is if we have reached the end of the file
; 	popf
; 	STC
; 	pushf
; 	mov	DX, 10	; set the value to be too low to do anything
;
; done:
; 	popf
; 	pop	SI
; 	pop	CX
; 	pop	BX
; 	pop	AX
; 	ret
; LoadNote	ENDP

; put the frequency from the input into BX and the timing into CX
; set the carry flag if there is more data in the file, clear it otherwise
ParseInput	PROC
	push	AX
	push	DX

	CLC	; we need this to pass on whether or not we are at the end of the file

	call	LoadDecimal
	mov	BX, DX

	call	LoadDecimal
	mov	CX, DX

	pop	DX
	pop	AX
	ret
ParseInput	ENDP

; play all the frequencies and timings in a file
PlayFile	PROC
top:
	call	ParseInput	; return the note frequency and duration in BX and CX

	; now that we have the note we can play it
	call	PlayNote

	jnc	top

done:
	ret
PlayFile	ENDP

main PROC
	mov	AX, @data
  mov	DS, AX

	call	SpeakerOn

	clc
	call	GetFilename
	call	GetHandle	; AX now has the file handle
	jc	skip

	call	PlayFile

skip:
	call	SpeakerOff

  mov     AX, EXITDOS
  int     DOS
main ENDP

END main

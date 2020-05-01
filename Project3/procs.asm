TITLE procs

; Nate Koike
; procs.asm
; Spring 2019

INCLUDE CS240.inc
.8086

SPACE = 32	; this is the ASCII code for the space character

.data
oldAX	WORD	?
oldBX	WORD	?
oldCX	WORD	?
oldDX	WORD	?
oldSI	WORD	?
oldDI	WORD	?
oldBP	WORD	?
oldSP	WORD	?
oldFL	WORD	?

; this was used for testing HexOut
Hexy	BYTE	0FFh, 0h, 1h, 10h, 0a1h

; this is the general error message
Error	BYTE	"Register "
RegName	BYTE	?, ?	; the register's name goes here
	BYTE	"'s value has changed. Old value: ", 0
ErrorC	BYTE	", New value: ", 0
Fin	BYTE	". ", 0

; this is the general flag error message
FlagN	BYTE	?
	BYTE	" Flag value has changed. Old value: ", 0
FlagC	BYTE	", New value: ", 0
FLagFin	BYTE	". ", 0
Set	BYTE	"set", 0
Clear	BYTE	"clear", 0

.code
; Save the machine's state using global variables in memory
SaveMachineState PROC
	mov	oldAX, AX
	mov	oldBX, BX
	mov	oldCX, CX
	mov	oldDX, DX
	mov	oldSI, SI
	mov	oldDI, DI
 	mov	oldBP, BP

	; save the value of SP before the function call
	push	BP
	mov	BP, SP
	add	BP, 4
	mov	oldSP, BP
	pop	BP

	; move the flags into memory by moving them into AX first
	push	AX
	pushf

	pushf
	pop	AX
	mov	oldFL, AX
	popf
 	pop	AX
 	ret
SaveMachineState ENDP

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

CompAX PROC
	pushf

	cmp	AX, oldAX
	je	done

	; this only runs if AX has changed
	push	DX

	mov	DL, 'A'
	mov	RegName, DL

	mov	DL, 'X'
	mov	[RegName + 1], DL

	mov	DX, OFFSET Error
	call	PrintString
	pop	DX

	push	AX
	mov	AX, oldAX
	call	PrintHexWord
	pop	AX

	push	DX
	mov	DX, OFFSET ErrorC
	call	PrintString
	pop	DX

	call	PrintHexWord

	push	DX
	mov	DX, OFFSET Fin
	call	PrintString
	pop	DX

done:
	popf
	ret
CompAX ENDP

CompBX PROC
	pushf

	cmp	BX, oldBX
	je	done

	; this only runs if AX has changed
	push	DX

	mov	DL, 'B'
	mov	RegName, DL

	mov	DL, 'X'
	mov	[RegName + 1], DL

	mov	DX, OFFSET Error
	call	PrintString
	pop	DX

	push	AX
	mov	AX, oldBX
	call	PrintHexWord
	pop	AX

	push	DX
	mov	DX, OFFSET ErrorC
	call	PrintString
	pop	DX

	push	AX
	mov	AX, BX
	call	PrintHexWord
	pop	AX

	push	DX
	mov	DX, OFFSET Fin
	call	PrintString
	pop	DX

done:
	popf
	ret
CompBX ENDP

CompCX PROC
	pushf

	cmp	CX, oldCX
	je	done

	; this only runs if AX has changed
	push	DX

	mov	DL, 'C'
	mov	RegName, DL

	mov	DL, 'X'
	mov	[RegName + 1], DL

	mov	DX, OFFSET Error
	call	PrintString
	pop	DX

	push	AX
	mov	AX, oldCX
	call	PrintHexWord
	pop	AX

	push	DX
	mov	DX, OFFSET ErrorC
	call	PrintString
	pop	DX

	push	AX
	mov	AX, CX
	call	PrintHexWord
	pop	AX

	push	DX
	mov	DX, OFFSET Fin
	call	PrintString
	pop	DX

done:
	popf
	ret
CompCX ENDP

CompDX PROC
	pushf

	cmp	DX, oldDX
	je	done

	; this only runs if AX has changed
	push	DX

	mov	DL, 'D'
	mov	RegName, DL

	mov	DL, 'X'
	mov	[RegName + 1], DL

	mov	DX, OFFSET Error
	call	PrintString
	pop	DX

	push	AX
	mov	AX, oldDX
	call	PrintHexWord
	pop	AX

	push	DX
	mov	DX, OFFSET ErrorC
	call	PrintString
	pop	DX

	push	AX
	mov	AX, DX
	call	PrintHexWord
	pop	AX

	push	DX
	mov	DX, OFFSET Fin
	call	PrintString
	pop	DX

done:
	popf
	ret
CompDX ENDP

CompSI PROC
	pushf

	cmp	SI, oldSI
	je	done

	; this only runs if AX has changed
	push	DX

	mov	DL, 'S'
	mov	RegName, DL

	mov	DL, 'I'
	mov	[RegName + 1], DL

	mov	DX, OFFSET Error
	call	PrintString
	pop	DX

	push	AX
	mov	AX, oldSI
	call	PrintHexWord
	pop	AX

	push	DX
	mov	DX, OFFSET ErrorC
	call	PrintString
	pop	DX

	push	AX
	mov	AX, SI
	call	PrintHexWord
	pop	AX

	push	DX
	mov	DX, OFFSET Fin
	call	PrintString
	pop	DX

done:
	popf
	ret
CompSI ENDP

CompDI PROC
	pushf

	cmp	DI, oldDI
	je	done

	; this only runs if AX has changed
	push	DX

	mov	DL, 'D'
	mov	RegName, DL

	mov	DL, 'I'
	mov	[RegName + 1], DL

	mov	DX, OFFSET Error
	call	PrintString
	pop	DX

	push	AX
	mov	AX, oldDI
	call	PrintHexWord
	pop	AX

	push	DX
	mov	DX, OFFSET ErrorC
	call	PrintString
	pop	DX

	push	AX
	mov	AX, DI
	call	PrintHexWord
	pop	AX

	push	DX
	mov	DX, OFFSET Fin
	call	PrintString
	pop	DX

done:
	popf
	ret
CompDI ENDP

CompBP PROC
	pushf

	cmp	BP, oldBP
	je	done

	; this only runs if AX has changed
	push	DX

	mov	DL, 'B'
	mov	RegName, DL

	mov	DL, 'P'
	mov	[RegName + 1], DL

	mov	DX, OFFSET Error
	call	PrintString
	pop	DX

	push	AX
	mov	AX, oldBP
	call	PrintHexWord
	pop	AX

	push	DX
	mov	DX, OFFSET ErrorC
	call	PrintString
	pop	DX

	push	AX
	mov	AX, BP
	call	PrintHexWord
	pop	AX

	push	DX
	mov	DX, OFFSET Fin
	call	PrintString
	pop	DX

done:
	popf
	ret
CompBP ENDP

; THIS NEEDS MORE WORK
; Stack after pushes
; +----------+
; |    BP    | <-- BP, SP
; +----------+
; |    FL    | <-- BP + 2
; +----------+
; |    RA    | <-- BP + 4
; +----------+
; |    FN    | <-- BP + 6
; +----------+
; |          |
CompSP PROC
	pushf
	push	BP

	mov	BP, SP
	add	BP, 10

	cmp	BP, oldSP
	je	done

	; this only runs if SP has changed
	push	DX

	mov	DL, 'S'
	mov	RegName, DL

	mov	DL, 'P'
	mov	[RegName + 1], DL

	mov	DX, OFFSET Error
	call	PrintString
	pop	DX

	push	AX
	mov	AX, oldSP
	call	PrintHexWord
	pop	AX

	push	DX
	mov	DX, OFFSET ErrorC
	call	PrintString
	pop	DX

	push	AX
	mov	AX, BP
	call	PrintHexWord
	pop	AX

	push	DX
	mov	DX, OFFSET Fin
	call	PrintString
	pop	DX

done:
	pop	BP
	popf
	ret
CompSP ENDP

; ==============================================================================
;                  THIS IS THE START OF THE FLAG COMPARISONS
; ==============================================================================

; THIS WILL ONLY CHECK ONE FLAG
CompOF PROC
	push	AX
	push	BX
	pushf

	; FLAGS REGISTER DIAGRAM
	; +15+14+13+12+11+10+09+08+ +07+06+05+04+03+02+01+00+
	; +--+--+--+--+--+--+--+--+ +--+--+--+--+--+--+--+--+
	; |  |  |  |  |OF|DF|IF|TF| |SF|ZF|  |AC|  |PF|  |CY|
	; +--+--+--+--+--+--+--+--+ +--+--+--+--+--+--+--+--+

	; put the flags into AX
	; AND with 0 eveyrwhere except the flag we care about and compare
	; the old value to the new value
	pushf
	pop	AX

	mov	BX, oldFL

	; check one flag
	push	AX

	AND	AX, 0800h
	AND	BX, 0800h

	cmp	AX, BX
	jne	change

done:
	pop	AX

	popf
	pop	BX
	pop	AX
	ret

change:
	cmp	AX, BX
	jb	lowered

raised:
	push	DX
	mov	DL, 'O'
	mov	FlagN, DL

	mov	DX, OFFSET FlagN
	call	PrintString

	mov	DX, OFFSET Clear
	call	PrintString

	mov	DX, OFFSET FlagC
	call	PrintString

	mov	DX, OFFSET Set
	call	PrintString

	mov	DX, OFFSET FlagFin
	call	PrintString

	pop	DX

	jmp	done

lowered:
	push	DX
	mov	DL, 'O'
	mov	FlagN, DL

	mov	DX, OFFSET FlagN
	call	PrintString

	mov	DX, OFFSET Set
	call	PrintString

	mov	DX, OFFSET FlagC
	call	PrintString

	mov	DX, OFFSET Clear
	call	PrintString

	mov	DX, OFFSET FlagFin
	call	PrintString

	pop	DX

	jmp	done

CompOF ENDP

; THIS WILL ONLY CHECK ONE FLAG
CompDF PROC
	push	AX
	push	BX
	pushf

	; FLAGS REGISTER DIAGRAM
	; +15+14+13+12+11+10+09+08+ +07+06+05+04+03+02+01+00+
	; +--+--+--+--+--+--+--+--+ +--+--+--+--+--+--+--+--+
	; |  |  |  |  |OF|DF|IF|TF| |SF|ZF|  |AC|  |PF|  |CY|
	; +--+--+--+--+--+--+--+--+ +--+--+--+--+--+--+--+--+

	; put the flags into AX
	; AND with 0 eveyrwhere except the flag we care about and compare
	; the old value to the new value
	pushf
	pop	AX

	mov	BX, oldFL

	; check one flag
	push	AX

	AND	AX, 0400h
	AND	BX, 0400h

	cmp	AX, BX
	jne	change

done:
	pop	AX

	popf
	pop	BX
	pop	AX
	ret

change:
	cmp	AX, BX
	jb	lowered

raised:
	push	DX
	mov	DL, 'D'
	mov	FlagN, DL

	mov	DX, OFFSET FlagN
	call	PrintString

	mov	DX, OFFSET	Clear
	call	PrintString

	mov	DX, OFFSET FlagC
	call	PrintString

	mov	DX, OFFSET Set
	call	PrintString

	mov	DX, OFFSET FlagFin
	call	PrintString

	pop	DX

	jmp	done

lowered:
	push	DX
	mov	DL, 'D'
	mov	FlagN, DL

	mov	DX, OFFSET FlagN
	call	PrintString

	mov	DX, OFFSET Set
	call	PrintString

	mov	DX, OFFSET FlagC
	call	PrintString

	mov	DX, OFFSET Clear
	call	PrintString

	mov	DX, OFFSET FlagFin
	call	PrintString

	pop	DX

	jmp	done

CompDF ENDP

; THIS WILL ONLY CHECK ONE FLAG
CompIF PROC
	push	AX
	push	BX
	pushf

	; FLAGS REGISTER DIAGRAM
	; +15+14+13+12+11+10+09+08+ +07+06+05+04+03+02+01+00+
	; +--+--+--+--+--+--+--+--+ +--+--+--+--+--+--+--+--+
	; |  |  |  |  |OF|DF|IF|TF| |SF|ZF|  |AC|  |PF|  |CY|
	; +--+--+--+--+--+--+--+--+ +--+--+--+--+--+--+--+--+

	; put the flags into AX
	; AND with 0 eveyrwhere except the flag we care about and compare
	; the old value to the new value
	pushf
	pop	AX

	mov	BX, oldFL

	; check one flag
	push	AX

	AND	AX, 0200h
	AND	BX, 0200h

	cmp	AX, BX
	jne	change

done:
	pop	AX

	popf
	pop	BX
	pop	AX
	ret

change:
	cmp	AX, BX
	jb	lowered

raised:
	push	DX
	mov	DL, 'I'
	mov	FlagN, DL

	mov	DX, OFFSET FlagN
	call	PrintString

	mov	DX, OFFSET Clear
	call	PrintString

	mov	DX, OFFSET FlagC
	call	PrintString

	mov	DX, OFFSET Set
	call	PrintString

	mov	DX, OFFSET FlagFin
	call	PrintString

	pop	DX

	jmp	done

lowered:
	push	DX
	mov	DL, 'I'
	mov	FlagN, DL

	mov	DX, OFFSET FlagN
	call	PrintString

	mov	DX, OFFSET Set
	call	PrintString

	mov	DX, OFFSET FlagC
	call	PrintString

	mov	DX, OFFSET Clear
	call	PrintString

	mov	DX, OFFSET FlagFin
	call	PrintString

	pop	DX

	jmp	done

CompIF ENDP

; THIS WILL ONLY CHECK ONE FLAG
CompTF PROC
	push	AX
	push	BX
	pushf

	; FLAGS REGISTER DIAGRAM
	; +15+14+13+12+11+10+09+08+ +07+06+05+04+03+02+01+00+
	; +--+--+--+--+--+--+--+--+ +--+--+--+--+--+--+--+--+
	; |  |  |  |  |OF|DF|IF|TF| |SF|ZF|  |AC|  |PF|  |CY|
	; +--+--+--+--+--+--+--+--+ +--+--+--+--+--+--+--+--+

	; put the flags into AX
	; AND with 0 eveyrwhere except the flag we care about and compare
	; the old value to the new value
	pushf
	pop	AX

	mov	BX, oldFL

	; check one flag
	push	AX

	AND	AX, 0100h
	AND	BX, 0100h

	cmp	AX, BX
	jne	change

done:
	pop	AX

	popf
	pop	BX
	pop	AX
	ret

change:
	cmp	AX, BX
	jb	lowered

raised:
	push	DX
	mov	DL, 'T'
	mov	FlagN, DL

	mov	DX, OFFSET FlagN
	call	PrintString

	mov	DX, OFFSET Clear
	call	PrintString

	mov	DX, OFFSET FlagC
	call	PrintString

	mov	DX, OFFSET Set
	call	PrintString

	mov	DX, OFFSET FlagFin
	call	PrintString

	pop	DX

	jmp	done

lowered:
	push	DX
	mov	DL, 'T'
	mov	FlagN, DL

	mov	DX, OFFSET FlagN
	call	PrintString

	mov	DX, OFFSET Set
	call	PrintString

	mov	DX, OFFSET FlagC
	call	PrintString

	mov	DX, OFFSET Clear
	call	PrintString

	mov	DX, OFFSET FlagFin
	call	PrintString

	pop	DX

	jmp	done

CompTF ENDP

; THIS WILL ONLY CHECK ONE FLAG
CompSF PROC
	push	AX
	push	BX
	pushf

	; FLAGS REGISTER DIAGRAM
	; +15+14+13+12+11+10+09+08+ +07+06+05+04+03+02+01+00+
	; +--+--+--+--+--+--+--+--+ +--+--+--+--+--+--+--+--+
	; |  |  |  |  |OF|DF|IF|TF| |SF|ZF|  |AC|  |PF|  |CY|
	; +--+--+--+--+--+--+--+--+ +--+--+--+--+--+--+--+--+

	; put the flags into AX
	; AND with 0 eveyrwhere except the flag we care about and compare
	; the old value to the new value
	pushf
	pop	AX

	mov	BX, oldFL

	; check one flag
	push	AX

	AND	AX, 0080h
	AND	BX, 0080h

	cmp	AX, BX
	jne	change

done:
	pop	AX

	popf
	pop	BX
	pop	AX
	ret

change:
	cmp	AX, BX
	jb	lowered

raised:
	push	DX
	mov	DL, 'S'
	mov	FlagN, DL

	mov	DX, OFFSET FlagN
	call	PrintString

	mov	DX, OFFSET Clear
	call	PrintString

	mov	DX, OFFSET FlagC
	call	PrintString

	mov	DX, OFFSET Set
	call	PrintString

	mov	DX, OFFSET FlagFin
	call	PrintString

	pop	DX

	jmp	done

lowered:
	push	DX
	mov	DL, 'S'
	mov	FlagN, DL

	mov	DX, OFFSET FlagN
	call	PrintString

	mov	DX, OFFSET Set
	call	PrintString

	mov	DX, OFFSET FlagC
	call	PrintString

	mov	DX, OFFSET Clear
	call	PrintString

	mov	DX, OFFSET FlagFin
	call	PrintString

	pop	DX

	jmp	done

CompSF ENDP

; THIS WILL ONLY CHECK ONE FLAG
CompZF PROC
	push	AX
	push	BX
	pushf

	; FLAGS REGISTER DIAGRAM
	; +15+14+13+12+11+10+09+08+ +07+06+05+04+03+02+01+00+
	; +--+--+--+--+--+--+--+--+ +--+--+--+--+--+--+--+--+
	; |  |  |  |  |OF|DF|IF|TF| |SF|ZF|  |AC|  |PF|  |CY|
	; +--+--+--+--+--+--+--+--+ +--+--+--+--+--+--+--+--+

	; put the flags into AX
	; AND with 0 eveyrwhere except the flag we care about and compare
	; the old value to the new value
	pushf
	pop	AX

	mov	BX, oldFL

	; check one flag
	push	AX

	AND	AX, 0040h
	AND	BX, 0040h

	cmp	AX, BX
	jne	change

done:
	pop	AX

	popf
	pop	BX
	pop	AX
	ret

change:
	cmp	AX, BX
	jb	lowered

raised:
	push	DX
	mov	DL, 'Z'
	mov	FlagN, DL

	mov	DX, OFFSET FlagN
	call	PrintString

	mov	DX, OFFSET Clear
	call	PrintString

	mov	DX, OFFSET FlagC
	call	PrintString

	mov	DX, OFFSET Set
	call	PrintString

	mov	DX, OFFSET FlagFin
	call	PrintString

	pop	DX

	jmp	done

lowered:
	push	DX
	mov	DL, 'Z'
	mov	FlagN, DL

	mov	DX, OFFSET FlagN
	call	PrintString

	mov	DX, OFFSET Set
	call	PrintString

	mov	DX, OFFSET FlagC
	call	PrintString

	mov	DX, OFFSET Clear
	call	PrintString

	mov	DX, OFFSET FlagFin
	call	PrintString

	pop	DX

	jmp	done

CompZF ENDP

; THIS WILL ONLY CHECK ONE FLAG
CompAF PROC
	push	AX
	push	BX
	pushf

	; FLAGS REGISTER DIAGRAM
	; +15+14+13+12+11+10+09+08+ +07+06+05+04+03+02+01+00+
	; +--+--+--+--+--+--+--+--+ +--+--+--+--+--+--+--+--+
	; |  |  |  |  |OF|DF|IF|TF| |SF|ZF|  |AC|  |PF|  |CY|
	; +--+--+--+--+--+--+--+--+ +--+--+--+--+--+--+--+--+

	; put the flags into AX
	; AND with 0 eveyrwhere except the flag we care about and compare
	; the old value to the new value
	pushf
	pop	AX

	mov	BX, oldFL

	; check one flag
	push	AX

	AND	AX, 0010h
	AND	BX, 0010h

	cmp	AX, BX
	jne	change

done:
	pop	AX

	popf
	pop	BX
	pop	AX
	ret

change:
	cmp	AX, BX
	jb	lowered

raised:
	push	DX
	mov	DL, 'A'
	mov	FlagN, DL

	mov	DX, OFFSET FlagN
	call	PrintString

	mov	DX, OFFSET Clear
	call	PrintString

	mov	DX, OFFSET FlagC
	call	PrintString

	mov	DX, OFFSET Set
	call	PrintString

	mov	DX, OFFSET FlagFin
	call	PrintString

	pop	DX

	jmp	done

lowered:
	push	DX
	mov	DL, 'A'
	mov	FlagN, DL

	mov	DX, OFFSET FlagN
	call	PrintString

	mov	DX, OFFSET Set
	call	PrintString

	mov	DX, OFFSET FlagC
	call	PrintString

	mov	DX, OFFSET Clear
	call	PrintString

	mov	DX, OFFSET FlagFin
	call	PrintString

	pop	DX

	jmp	done

CompAF ENDP

; THIS WILL ONLY CHECK ONE FLAG
CompPF PROC
	push	AX
	push	BX
	pushf

	; FLAGS REGISTER DIAGRAM
	; +15+14+13+12+11+10+09+08+ +07+06+05+04+03+02+01+00+
	; +--+--+--+--+--+--+--+--+ +--+--+--+--+--+--+--+--+
	; |  |  |  |  |OF|DF|IF|TF| |SF|ZF|  |AC|  |PF|  |CY|
	; +--+--+--+--+--+--+--+--+ +--+--+--+--+--+--+--+--+

	; put the flags into AX
	; AND with 0 eveyrwhere except the flag we care about and compare
	; the old value to the new value
	pushf
	pop	AX

	mov	BX, oldFL

	; check one flag
	push	AX

	AND	AX, 0004h
	AND	BX, 0004h

	cmp	AX, BX
	jne	change

done:
	pop	AX

	popf
	pop	BX
	pop	AX
	ret

change:
	cmp	AX, BX
	jb	lowered

raised:
	push	DX
	mov	DL, 'P'
	mov	FlagN, DL

	mov	DX, OFFSET FlagN
	call	PrintString

	mov	DX, OFFSET Clear
	call	PrintString

	mov	DX, OFFSET FlagC
	call	PrintString

	mov	DX, OFFSET Set
	call	PrintString

	mov	DX, OFFSET FlagFin
	call	PrintString

	pop	DX

	jmp	done

lowered:
	push	DX
	mov	DL, 'P'
	mov	FlagN, DL

	mov	DX, OFFSET FlagN
	call	PrintString

	mov	DX, OFFSET Set
	call	PrintString

	mov	DX, OFFSET FlagC
	call	PrintString

	mov	DX, OFFSET Clear
	call	PrintString

	mov	DX, OFFSET FlagFin
	call	PrintString

	pop	DX

	jmp	done

CompPF ENDP

; THIS WILL ONLY CHECK ONE FLAG
CompCF PROC
	push	AX
	push	BX
	pushf

	; FLAGS REGISTER DIAGRAM
	; +15+14+13+12+11+10+09+08+ +07+06+05+04+03+02+01+00+
	; +--+--+--+--+--+--+--+--+ +--+--+--+--+--+--+--+--+
	; |  |  |  |  |OF|DF|IF|TF| |SF|ZF|  |AC|  |PF|  |CY|
	; +--+--+--+--+--+--+--+--+ +--+--+--+--+--+--+--+--+

	; put the flags into AX
	; AND with 0 eveyrwhere except the flag we care about and compare
	; the old value to the new value
	pushf
	pop	AX

	mov	BX, oldFL

	; check one flag
	push	AX

	AND	AX, 0001h
	AND	BX, 0001h

	cmp	AX, BX
	jne	change

done:
	pop	AX

	popf
	pop	BX
	pop	AX
	ret

change:
	cmp	AX, BX
	jb	lowered

raised:
	push	DX
	mov	DL, 'C'
	mov FlagN, DL

	mov	DX, OFFSET FlagN
	call	PrintString

	mov	DX, OFFSET Clear
	call	PrintString

	mov	DX, OFFSET FlagC
	call	PrintString

	mov	DX, OFFSET Set
	call	PrintString

	mov	DX, OFFSET FlagFin
	call	PrintString

	pop	DX

	jmp	done

lowered:
	push	DX
	mov	DL, 'C'
	mov	FlagN, DL

	mov	DX, OFFSET FlagN
	call	PrintString

	mov	DX, OFFSET Set
	call	PrintString

	mov	DX, OFFSET FlagC
	call	PrintString

	mov	DX, OFFSET Clear
	call	PrintString

	mov	DX, OFFSET FlagFin
	call	PrintString

	pop	DX

	jmp	done

CompCF ENDP

; compare the current machine state to the one saved in memory and output the
; differences (if any)
CompareMachineState PROC
	pushf

	call	CompAX
	call	CompBX
	call	CompCX
	call	CompDX
	call	CompSI
	call	CompDI
	call	CompBP
	call	CompSP

	; FLAGS REGISTER DIAGRAM
	; +15+14+13+12+11+10+09+08+ +07+06+05+04+03+02+01+00+
	; +--+--+--+--+--+--+--+--+ +--+--+--+--+--+--+--+--+
	; |  |  |  |  |OF|DF|IF|TF| |SF|ZF|  |AF|  |PF|  |CF|
	; +--+--+--+--+--+--+--+--+ +--+--+--+--+--+--+--+--+

	call	CompOF
	call	CompDF
	call	CompIF
	call	CompTF
	call	CompSF
	call	CompZF
	call	CompAF
	call	CompPF
	call	CompCF

	popf
 	ret
CompareMachineState ENDP

; a recursive factorial function that takes a number in AX and returns the
; answer in AX
Fact PROC
	push	BX
	push	DX
	pushf

	cmp	AX, 2
	jb	zero

	; preserve the value of AX through the recursion
	mov	BX, AX

	; prepare to recursively call the function
	dec	AX

	; resurcively call factorial
	call	Fact

	; save the value from the recursive definition
	mov	DX, AX

	; restore the value of AX
	mov	AX, BX

	; AX still has the original value
	mul	DX

done:
	popf
	pop	DX
	pop	BX
	ret

zero:
	mov	AX, 1
	jmp	done

Fact ENDP

; write the contents of memory starting from the address stored in BX and print
; a number of characters equal to the number in CX
HexOut PROC
	push	BX
	push	CX
	push	DX
	pushf

compare:
	cmp	CX, 0
	je	done

start:
	mov	DL, [BX]

	call	PrintHexByte

	; NOTE: PRINT A SPACE AFTER EACH BYTE
	mov	DX, SPACE
	call	PrintChar

	inc	BX
	dec	CX
	jmp	compare

done:
	popf
	pop	DX
	pop	CX
	pop	BX
	ret
HexOut ENDP

; this function prints the sign of AX then performs 2's complement if AX
; is holding a number less than 0
PrintSign PROC
	push	DX
	pushf

	cmp	AX, 0
	jg	done

	NOT	AX	; flip all the bits of AX and ...
	inc	AX	; ... add 1 to AX, thus completing 2's complement
	mov	DL, '-'	; this should be the ASCII value of '-'
	call	PrintChar	; print the negative sign

done:
	popf
	pop	DX
	ret
PrintSign ENDP

; write the unsingned integer in AX to the screen, this cannot print 0
PrintUInt PROC
	pushf
	push	DX

	cmp	AX, 0
	je	done

	; get the remainder in DX
	push	BX
	mov	BX, 10
	mov	DX, 0
	div	BX
	pop	BX

	; resursively call this function to get all the other digits
	call	PrintUInt

	call PrintHexDigit

	done:
	pop	DX
	popf
	ret
PrintUInt ENDP

; print a signed integer stored in AX
PrintInt PROC
	push	AX
	pushf

	cmp	AX, 0
	je	zero

	call	PrintSign
	call	PrintUInt

done:
	popf
	pop	AX
	ret

zero:
	push	DX
	mov	DL, '0'
	call	PrintChar
	pop	DX
	jmp	done

PrintInt ENDP

END

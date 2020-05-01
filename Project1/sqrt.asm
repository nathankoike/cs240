TITLE sqrt

; sqrt.asm
; Nate Koike
; Spring 2019

; finds the square root of a 16-bit unsigned integer

INCLUDE CS240.inc
.8086

CALLDOS=4C00h
DOS=21h

.data
odd          WORD   1
userPrompt   Byte   "Enter a number: ", 0

.code
sqrt PROC
     ; preserve the state of the machine
     push AX
     push DS
     pushf

     ; check for the zero cases
     cmp AX, 2
     jb  zero

     mov DX, 0 ; reset the value of DX so we can iterate cleanly

start:
     ; see if we can increment through the process again
     cmp AX, odd
     jb  round

     ; this process progressively adds odd numbers in a process in which
     ; the number of additions is equal to the square root of the sum of
     ; the odd numbers added in the sequence
     sub AX, odd
     add odd, 2
     add DX, 1
     jmp start

; check to see if we need to round up or round down
round:
     add DX, 1
     cmp AX, DX
     jb  done
     add DX, 1

done:
     ; restore the state of the machine
     sub DX, 1
     popf
     pop DS
     pop AX

     ret

zero:
     add DX, 1
     jmp done

sqrt ENDP

main PROC
     push DS
     pushf

     ; move variables into data segment
     mov AX, @data
     mov DS, AX

     ; prompt the user to enter a number
     mov DX, OFFSET userPrompt
     call WriteString	

     ; read in an integer and move it into AX
     call ReadUInt
     mov AX, DX

     call sqrt
     call WriteInt
     call NewLine

     popf
     pop DS
     mov AX, CALLDOS
     int DOS
main ENDP
END main

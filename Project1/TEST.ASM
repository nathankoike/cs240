TITLE test

INCLUDE CS240.inc
.8086

.data

.code
main PROC
     call DumpRegs
     mov AX, 4C00h
     int 21h
main ENDP
END main

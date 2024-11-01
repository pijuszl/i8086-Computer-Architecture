.model small
    rdBufferSize EQU 255			;reading buffer size
    wrbufferSize  EQU 255			;writing buffer size
.stack 100h
.data
	fData1	db rdBufferSize dup(0)	;first reading file name
	reBuff1	db rdBufferSize dup(0)	;first reading file buffer
	
	fData2	db rdBufferSize dup(0)  ;second reading file name
	reBuff2 db rdBufferSize dup(0)  ;second reading file buffer
	
	fWrite	db wrBufferSize dup(0)	;writing filne name    
	wrBuff	db wrBufferSize dup(0)	;writing file buffer
	
	inputLength dw 0
	
	reFile1	dw 0			;holds first reading file handle
	reFile2 dw 0            ;holds second reading file handle
	wrFile	dw 0			;holds writing file handle
	
	readSize1   dw 0		;how many characters are in a buffer
	readSize2   dw 0
	arraySize   dw 0
	
	help1 db "To run a program which adds two octal number, it needs names of data and results files to be specified after programs name", 0dh, 0ah, '$'
	help2 db "A file does not exist or it can not be opened", 0dh, 0ah, '$'
.code
  start:
 
	MOV	ax, @data                        
	MOV	ds, ax			    ;data segment
    
    MOV bx, 82h
    MOV si, offset fData1
	
    CMP byte ptr es:[80h], 0
    JE error1
	
	mov ch, 0
	mov cl, es:[80h]
	MOV	bx, 81h
	
	findHelp:
	CMP	es:[bx], '?/'
	JE	error1
	INC	bx
	LOOP findHelp
	
	mov bx, 82h
    
    cycle1:					;reads first file name
	CMP byte ptr es:[bx], ' '
    JNE ifNoSpace1
    CMP inputLength, 0
	JE	error1
	
	CMP inputLength, 0
    JA f_read
    INC bx 
    JMP cycle1
	
    ifNoSpace1:
    CMP byte ptr es:[bx], 13 
    JE error1
    
    MOV dl, byte ptr es:[bx]
	MOV [si], dl
	
	INC bx
    INC si
    INC inputLength 
    JMP cycle1
    
    f_read:
    MOV	ah, 3Dh             ;opens first file to read
	MOV	al, 00
	MOV	dx, offset fData1
	INT	21h
	JC error2
	MOV	reFile1, ax
	
    MOV bp, bx                       
    MOV si, offset fData2 
    INC bx
    MOV inputLength, 0        
    
    cycle2:					;reads second file name 
	CMP byte ptr es:[bx], ' '
    JNE ifNoSpace2
    CMP inputLength, 0
	JE	error1
	
	CMP inputLength, 0
    JA readFile
    INC bx 
    JMP cycle2
    
    error1:
    CALL errorParameters
    error2:
    CALL errorWorkingWithFiles
    CALL closeReadingFiles 
	
    ifNoSpace2:
    CMP byte ptr es:[bx], 13 
    JE error1
    
    MOV dl, byte ptr es:[bx]
	MOV [si], dl 
	
	INC bx
    INC si
    INC inputLength 
    JMP cycle2
    
    readFile:
    MOV	ah, 3Dh				;opens second file to read
	MOV	al, 00
	MOV	dx, offset fData2
	INT	21h
	JC error2
	MOV	reFile2, ax
	
    MOV bp, bx                      
    MOV si, offset fWrite
    INC bx
    MOV inputLength, 0 
	
    cycle3:					;reads writing file name
    CMP byte ptr es:[bx], ' '
    JNE ifNoSpace3
    CMP inputLength, 0
    JE error1
    
	CMP byte ptr es:[bx], 13 
    JE skipInput     
    INC bx
    JMP cycle3
    
    ifNoSpace3:
    CMP byte ptr es:[bx], 13 
    JNE skipIfnot
    CMP inputLength, 0
	JE	error1
	JMP skipInput
	skipIfnot:
    
    MOV dl, byte ptr es:[bx]
	MOV [si], dl
	
	INC bx
    INC si
    INC inputLength 
    jmp cycle3 
	
	skipInput:
	
	MOV	ah, 3Ch				;creates and opens file to write
	MOV	cx, 0
	MOV	dx, offset fWrite
	INT	21h
	JC	error3
	MOV	wrFile, ax
	MOV ax, 0
	
	MOV	bx, reFile1			;reads from first file
	CALL readFirstFile
	CMP	ax, 0
	JE	error4
	MOV readSize1, ax
	MOV ax, 0
	
	MOV	bx, reFile2			;reads from second file
	CALL readSecondFile
	CMP	ax, 0
	JE	error4
	MOV readSize2, ax
	
	JMP ignore					
    error3:
    CALL errorWorkingWithFiles
    CALL closeReadingFiles
    error4:
    CALL errorWorkingWithFiles
    CALL closeAllFiles
    ignore:
	

	MOV ax, 0
	MOV bx, 0
	MOV dx, 0
	
	MOV	si, offset reBuff1 + 100	;adding numbers and writing results to buffer
	ADD si, readSize1
	DEC si
	
	MOV	di, offset reBuff2 + 100
	ADD di, readSize2
	DEC di
	
    MOV cx, readSize1
    CMP cx, readSize2
    JA skipSize
    MOV cx, readSize2
    skipSize:
    
	
	JMP ignore1
	ifSpace1:
	DEC si
	ignore1:
	
    addNumbers:
    MOV al, [si]
	MOV ah, 0
	
	CMP al, 20h
	JE ifSpace1
    CMP al, 0
    JE ifZero1
    SUB al, 30h
    ifZero1:
	
    ADD ax, bx
	
	JMP ignore2
	ifSpace2:
	DEC di
	DEC cx
	ignore2:
	
    MOV bl, [di]
	MOV bh, 0
	CMP bl, 20h
	JE ifSpace2
    CMP bx, 0
    JE ifZero2
    SUB bl, 30h
    ifZero2:
	
    ADD ax, bx
    MOV bx, 8
    DIV bx
    MOV bx, ax
    
    MOV ax, dx
    MOV dx, 0
    CMP bx, 0
    JE skip
	
    CMP cx, 1	;checks if there is no space for number
    JNE skip
    INC cx   
	
    skip:
    PUSH ax
	DEC	si
	DEC	di
	INC arraySize
	LOOP addNumbers
	
	MOV	di, offset wrBuff
	MOV cx, arraySize
	MOV ax, 0
	
	writeFromStack:             ;writes numbers from stack to buffer
	POP ax
	ADD al, 30h
	MOV [di], al
	
	INC di
	LOOP writeFromStack
	
	MOV	cx, arraySize
	MOV	bx, wrFile
	CALL	writeToFile		;call procedure to write in file
  
    CALL closeAllFiles
    
PROC readFirstFile			;reads from first file
	PUSH cx
	PUSH dx
	
	MOV	ah, 3Fh
	MOV	cx, rdBufferSize - 100
	MOV	dx, offset reBuff1 + 100
	INT	21h
	JC	errorReading1

	readEnd1:
	POP	dx
	POP cx
	RET

	errorReading1:
	MOV ax, 0
	JMP	readEnd1
readFirstFile ENDP

PROC readSecondFile			;reads from second file
	PUSH	cx
	PUSH	dx
	
	MOV	ah, 3Fh
	MOV	cx, rdBufferSize - 100
	MOV	dx, offset reBuff2 + 100
	INT	21h
	JC	errorReading2

	readEnd2:
	POP	dx
	POP	cx
	RET

	errorReading2:
	MOV ax, 0
	JMP	readEnd2
readSecondFile ENDP

PROC writeToFile			;write result to buffer
	PUSH dx
	PUSH ax
	
	MOV	ah, 40h
	MOV	dx, offset wrBuff
	INT	21h
	JC	errorWriting
	;CMP	cx, ax

	writeEnd:
	POP	ax
	POP dx
	RET
	
	errorWriting:
	MOV	ax, 0
	JMP	writeEnd
writeToFile ENDP

PROC errorParameters	;prints help and ends program
	
    MOV dx, offset help1  
    MOV ah, 09h
	MOV	al, 0	
    INT 21h
	
    CALL endProgram    
errorParameters ENDP

PROC errorWorkingWithFiles		;prints error
	PUSH ax
	PUSH dx
	
    MOV dx, offset help2  
    MOV ah, 09h
	MOV	al, 0
    INT 21h
	
	POP dx
	POP ax	
	RET
errorWorkingWithFiles ENDP

PROC closeReadingFiles			;closes reading files
	MOV	ah, 3Eh
	MOV	bx, reFile1
	INT	21h
	JC	errorClosingFile
    
	MOV	ah, 3Eh
	MOV	al, 0
	MOV	bx, reFile2
	INT	21h
	JC	errorClosingFile
	CALL endProgram
	
	errorClosingFile:
	CALL errorWorkingWithFiles
	CALL endProgram    
closeReadingFiles ENDP

PROC closeAllFiles				;closes writing and then closes reading files
	
	MOV	ah, 3Eh
	MOV	al, 0
	MOV	bx, wrFile
	INT	21h
	JC	errorClosingWritingFIle
	
	CALL closeReadingFiles
	
	errorClosingWritingFIle:
	CALL errorWorkingWithFiles
	CALL closeReadingFiles
	
closeAllFiles ENDP

PROC endProgram					;end program
    MOV	ah, 4Ch
	MOV	al, 0
	INT	21h            
endProgram ENDP

END start
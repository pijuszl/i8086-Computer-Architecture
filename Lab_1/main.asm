.MODEL small	; memory model
.STACK 100h		; stack size
.DATA			; data segment
message_1 db 'Enter integer between 0 and 65535:', 0dh, 0ah, '$'
message_2 db 'Binary number is:', 0dh, 0ah, '$'
new_line db 0dh, 0ah, '$'
array db 6, 7 dup(?)
count dw 0
multiplier dw 0 
.CODE			; code segment
strt:
mov ax, @data
mov ds, ax		; data segment register inisialization

; prints first message
mov ah, 9
mov dx, offset message_1
int 21h
mov ax, 0
	
; takes input
mov ah, 0Ah
mov dx, offset array
int 21h
mov ax, 0

; finds how many symbols were inputted
mov si, offset array + 1
mov cl, [si]
mov ch, 0
add si, cx ; shifts address to last symbol
mov count, cx
	
; initialization of decimal number and multiplier 
mov bx, 0
mov multiplier, 1

; converts inputted symbols to decimal number
conversion_to_decimal:                             
mov al, [si]
sub al, 30h
mov ah, 0

mov cx, multiplier
mul cx
add bx, ax

mov ax, 0
mov ax, cx
mov cx, 10
mul cx
mov cx, 0
mov cx, count
	mov multiplier, ax
	
dec si
dec cx
mov count, cx
cmp cx, 0
je end_conversion_to_decimal
jmp conversion_to_decimal
end_conversion_to_decimal:

; empties registers and defines divisor
mov ax, 0
mov dx, 0
mov cx, 2

; converts decimal number to binary number
; divides number by 2 and pushes remainder to stack
conversion_to_binary:    
mov ax, bx
div cx
mov bx, ax
	
; pushes raimainder to stack
push dx
inc count

mov dx, 0
cmp bx, 0
je end_conversion_to_binary
jmp conversion_to_binary
end_conversion_to_binary:

; prtints new line and second message
mov ah, 9
mov dx, offset new_line
int 21h

mov dx, offset message_2
int 21h
mov ax, 0

; prints numbers from stack 
print:
cmp count,0
je end_print

; takes number and turns it symbol '1' or '0'
pop dx
mov al, dl
add al, 30h


mov ah, 2
mov dl, al
int 21h

dec count
jmp print
end_print:


mov ax,4C00h	; program work end
int 21h
end strt
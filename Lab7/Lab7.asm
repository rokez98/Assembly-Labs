; Написать программу, последовательно запускающую программы, которые расположены в заданном каталоге. 

;-------------------MACRO-----------------
newline MACRO
	push ax
	push dx

	;print new line
	mov dl, 10
	mov ah, 02h
	int 21h

	mov dl, 13
	mov ah, 02h
	int 21h

	pop dx
	pop ax
ENDM

println MACRO info
	push ax
	push dx

	mov ah, 09h
	mov dx, offset info
	int 21h

	newline

	pop dx
	pop ax
ENDM

;	Input:
;		ax - error code
printErrorCode MACRO
	add al, '0'
	mov dl, al
	mov ah, 06h
	int 21h

	newline
ENDM
;-----------------end macro----------------

;Параметр 1: путь к требуемой папке
.model small
.286

.data

cmd_size db ?

maxCMDSize equ 127
cmd_text db maxCMDSize + 2 dup(0)
folderPath db maxCMDSize + 2 dup(0)

;Disk Transfer Area
DTAsize equ 2Ch
DTAblock db DTAsize dup(0)

maxWordSize equ 50
buffer db maxWordSize + 2 dup(0)

PathToRequredEXE db maxCMDSize + 15 dup(0)
newProgramCMD db 0

spaceSymbol equ ' '
newLineSymbol equ 13
returnSymbol equ 10
tabulation equ 9

ASCIIZendl equ 0

startText db "Program is started", '$'
badCMDArgsMessage db "Bad command-line arguments. I want only 1 argument: folder path", '$'
endText db "Program is ended", '$'
initToRunErrorText db "Bad init to run other programs. Error code: ", '$'
runEXEErrorText db "Error running other program. Error code: ", '$'
badFolderErrorText db "Error forder to programs", '$'

;EXEC Parameter Block
EPBstruct 	dw 0
			dw offset line,0
			dw 005Ch,0,006Ch,0		;Адреса FCB (File control block) программы
line db 125
	 db " /?"
line_text db 122 dup(?)

EPBlen dw $ - EPBstruct

findSuffix db "*.exe", 0

DataSize=$-cmd_size

.stack 100h
.code

main:
	;reallocating memory
	mov ah, 4Ah
	mov bx, ((CodeSize/16)+1)+((DataSize/16)+1)+32	;требуемый размер в параграфах
	int 21h

	jnc initToRunAllGood

	println initToRunErrorText

	printErrorCode

	mov ax, 1

	jmp endMain

initToRunAllGood:
	mov ax, @data
	mov es, ax

	xor ch, ch
	mov cl, ds:[80h]			;ds еще стоит на начале PSP
	mov cmd_size, cl 		;сохраняем размер строки
	mov si, 81h
	mov di, offset cmd_text
	rep movsb
	;теперь в cmd_text то, что было записано в командную строку
	;а в cmd_size - размер

	mov ds, ax

	println startText

	call parseCMD
	cmp ax, 0
	jne endMain				;Какая-то ошибка - выход
	
	;change directory ot required
	mov ah, 3Bh
    mov dx, offset folderPath
    int 21h
    jc badWay

	call findFirstFile
	cmp ax, 0
	jne endMain				;Какая-то ошибка - выход

	call runEXE
	cmp ax, 0
	jne endMain				;Какая-то ошибка - выход

runFile:
	call findNextFile
	cmp ax, 0
	jne endMain				;Какая-то ошибка - выход

	call runEXE
	cmp ax, 0
	jne endMain				;Какая-то ошибка - выход

	jmp runFile

badWay:
	println badFolderErrorText
endMain:
	;exit
	println endText

	mov ah, 4Ch
	int 21h

;MACRO HELP
cmpWordLenWith0 MACRO textline, is0Marker
	push si
	mov si, offset textline
	call strlen
	pop si
	cmp ax, 0
	je is0Marker
ENDM
;end macro help


;Result in ax: 0 if all is good, else not
parseCMD PROC
	push bx cx dx

	mov cl, cmd_size
	xor ch, ch

	mov si, offset cmd_text
	mov di, offset buffer
	call rewriteAsASCIIZWord

	mov di, offset folderPath
	call rewriteAsASCIIZWord
	cmpWordLenWith0 folderPath, badCMDArgs

	mov di, offset buffer
	call rewriteAsASCIIZWord

	cmpWordLenWith0 buffer, argsIsGood

badCMDArgs:
	println badCMDArgsMessage
	mov ax, 1

	jmp endproc

argsIsGood:
	mov ax, 0

endproc:
	pop dx cx bx
	ret	
ENDP

;ds:si - offset, where needed ASCIIZ string is located
;RES: ax - length
strlen PROC
	push bx si
	xor ax, ax

startCalc:
	mov bl, ds:[si] 
	cmp bl, ASCIIZendl
	je endCalc

	inc si
	inc ax
	jmp startCalc
	
endCalc:
	pop si bx
	ret
ENDP

;ds:si - offset, where we will find (result stop will be in si too)
;es:di - offset, where word will be
;cx - maximum size of word (input)
;result will be ASCIIZ
rewriteAsASCIIZWord PROC
	push ax cx di
	
loopParseWord:
	mov al, ds:[si]
	cmp al, spaceSymbol
	je isStoppedSymbol

	cmp al, newLineSymbol
	je isStoppedSymbol

	cmp al, tabulation
	je isStoppedSymbol

	cmp al, returnSymbol
	je isStoppedSymbol

	cmp al, ASCIIZendl
	je isStoppedSymbol

	mov es:[di], al

	inc di
	inc si

	loop loopParseWord

isStoppedSymbol:
	mov al, ASCIIZendl
	mov es:[di], al
	inc si

	pop di cx ax
	ret
ENDP

;	Result
;		ax = 0 => all is good
;		ax != 0 => we have an error
runEXE PROC
	push bx dx

	mov ax, 4B00h				;загрузить и выполнить
	mov bx, offset EPBstruct
	mov dx, offset DTAblock + 1Eh	;получаем имя файла из DTA
	int 21h
	
	jnc runEXEAllGood

	println runEXEErrorText
	printErrorCode

	mov ax, 1

	jmp runEXEEnd

runEXEAllGood:
	mov ax, 0

runEXEEnd:
	pop dx bx
	ret
ENDP

installDTA PROC
	mov ah,1Ah
    mov dx, offset DTAblock
    int 21h
    ret
ENDP

;Result in ax: 0 if all is good, else not
findFirstFile PROC
	call installDTA

    ;fild first file
    mov ah,4Eh
    xor cx,cx               		; атрибут файла для сравнения 
    mov dx, offset findSuffix       ; адрес строки с именем файла
    int 21h

	jnc findFirstFileAllGood

	mov ax, 1

	jmp findFirstFileEnd

findFirstFileAllGood:
	mov ax, 0

findFirstFileEnd:

	ret
ENDP

;Result in ax: 0 if all is good, else not
findNextFile PROC
	call installDTA

	mov ah,4Fh
    mov dx, offset DTAblock       ; адрес строки с именем файла
    int 21h

	jnc findNextFileAllGood

	mov ax, 1

	jmp findNextFileEnd

findNextFileAllGood:
	mov ax, 0

findNextFileEnd:

	ret
ENDP

CodeSize = $ - main

end main
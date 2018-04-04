.model small

.stack 100h

.data    
readedTotal           dw  0
writedTotal           dw  0

maxCMDSize equ 127
cmd_size              db  ?
cmd_text              db  maxCMDSize + 2 dup(0)
sourcePath            db  maxCMDSize + 2 dup(0) 
;sourcePath            db  "text.txt", 0
       
                      
sourceID              dw  0
                      
maxWordSize           equ 50
buffer                db  maxWordSize + 2 dup(0)
                            
spaceSym              db  " ","$"                            
                            
spaceSymbol           equ ' '
newLineSymbol         equ 0Dh
returnSymbol          equ 0Ah
tabulation            equ 9
endl                  equ 0
                      
startText             db  "Program is started",                                               '$'
badCMDArgsMessage     db  "Bad command-line arguments. Only 1 argument required: source path",'$'
badSourceText         db  "Cannot open source file",                                          '$'
fileNotFoundText      db  "File not found",                                                   '$'
errorClosingSource    db  "Cannot close source file",                                         '$' 
errorWritingText      db  "Error writing to file",                                            '$'
endText               db  "Program is ended",                                                 '$'
errorReadSourceText   db  "Error reading from source file",                                   '$'
EOF                   db  0

period                equ 2
currWordStartingValue equ 0
currWordIndex         db  currWordStartingValue	;

.code  

println MACRO info          ;
	push ax                 ;
	push dx                 ;
                            ;
	mov ah, 09h             ; Команда вывода 
	lea dx, info            ; Загрузка в dx смещения выводимого сообщения
	int 21h                 ; Вызов прервывания для выполнения вывода
                            ;
	mov dl, 0Ah             ; Символ перехода на новую строку
	mov ah, 02h             ; Команда вывода символа
	int 21h                 ; Вызов прерывания
                            ;
	mov dl, 0Dh             ; Символ перехода в начало строки   
	mov ah, 02h             ;
	int 21h                 ;            ==//==
                            ;
	pop dx                  ;
	pop ax                  ;
ENDM

main:
	mov ax, @data           ; Загружаем данные
	mov es, ax              ;
                            ;
	xor ch, ch              ; Обнуляем ch
	mov cl, ds:[80h]		; Смещеие для дальнейшей работы с командой строкой
	mov cmd_size, cl 		; В cmd_size загружаем длину командной строки
	mov si, 81h             ;
	lea di, cmd_text        ; Загружаем в di смещение текста переданного через командную строку
	rep movsb               ; Записать в ячейку адресом ES:DI байт из ячейки DS:SI
                            ;
	mov ds, ax              ; Загружаем в ds данные
                            ;
	println startText       ; Вывод строки о начале работы программы
                            ;
	call parseCMD           ; Вызов процедуры парсинга командной строки
	cmp ax, 0               ;
	jne endMain				; Если ax != 0, т.е. при выполении процедуры произошла ошибка - переходим к конце программы, т.е. прыгаем в endMain
                            ;
	call openFiles          ; Вызываем процедуру, которая открывает оба файла для чтения/записи
	cmp ax, 0               ;
	jne endMain				;  ==//==
                            ;
	call processingFile     ; Главная процедура, в которой содержится весь алгоритм обработки файла
	cmp ax, 0               ; 
	jne endMain				;  ==//==
                            ;
	call closeFiles         ; Завершив обработку информации, вызываем процедуру закрытия файлов
	cmp ax, 0               ;
	jne endMain				;  ==//==
                            ;
endMain:                    ;
	println endText         ; Выводим сообщение о завершении работы программы
                            ;
	mov ah, 4Ch             ; Загружаем в ah код команды завершения работы
	int 21h                 ; Вызов прерывания DOS для ее исполнения


cmpWordLenWith0 MACRO textline, is0Marker       ; Сравнение строки с нулем, 1 параметр - строка, 2 условие перехода при 0
	push si                                     ; Сохранение значение регистра si
	                                            ;
	lea si, textline                            ; Загружаем в si смещение строки, в которой измеряем длинну
	call    strlen                              ; Вызываем ф-цию нахождения длины строки textline, результат -> ax
	                                            ;
	pop si                                      ; Восстанавливаем значение si
	cmp ax, 0                                   ; Сравниваем найденную длинну с нулем
	je is0Marker                                ; Если длина равна нулю -> переходим по переданной метке is0Marker
ENDM                                            ;                               ;
                                                ; 
                                                                                        ;                               ;
                                                        
                                                ;
;**************************************************************************************************************************
parseCMD PROC                                   ;
	push bx                                     ;
	push cx                                     ;
	push dx                                     ; Сохраняем
                                                ;
	mov cl, cmd_size                            ; Загружаем в cl размер командой строки
	xor ch, ch                                  ; Обнуляем ch
                                                ;
	lea si, cmd_text                            ; В si загружаем смещение данных из командой строки
	                                            ;                                                          
	lea di, buffer                              ; В di загружаем смещение буффера для обработки данных      
	call rewriteAsWord                          ;                                                           
                                                ;                                                           
	lea di, sourcePath                          ; Загружаем в di смещение sourcePath т.е. источника текста для обработки
	call rewriteAsWord                          ;
                                                ;
	cmpWordLenWith0 sourcePath, badCMDArgs      ; Если строка, содержащая название исзодног файла пуста, прыгаем в badCMDArgs  
	;checkTxt        sourcePath, badCMDArgs
                                                ; 
	lea di, buffer                              ; 
	call rewriteAsWord                          ;
                                                ;
	cmpWordLenWith0 buffer, argsIsGood          ; Если больше данных нет, т.е. кроме названия выходного и выходного файлов командная строка ничего не содержит
                                                ; то вызов программы корректный - прыгаем в argsIsGood
badCMDArgs:                                     ;
	println badCMDArgsMessage                   ; Выводим сообщение о неверных параметрах командной строки
	mov ax, 1                                   ; Записываем в ax код ошибки
                                                ;
	jmp endproc                                 ; Прыгаем в endproc и завершаем процедуру
                                                ;
argsIsGood:                                     ;
	mov ax, 0                                   ; Записываем в ax код успешного завершения процедуры
endproc:                                        ;
	pop dx                                      ;
	pop cx                                      ;
	pop bx                                      ; Восстанавливаем значения регистров и выходим из процедуры
	ret	                                        ;
ENDP
;*************************************************************************************************************************  
  
;*************************************************************************************************************************
;cx - Длина командной строки
;Результат - переписывает параметр из коммандной строки 
rewriteAsWord PROC              ;
	push ax                     ;
	push cx                     ;
	push di                     ; Сохраняеи регистры
	                            ;
loopParseWord:                  ;
	mov al, ds:[si]             ; Загружаем в al текущий символ
	
	cmp al, spaceSymbol         ; -------------------
    je isStoppedSymbol          ;                                 ;
	cmp al, newLineSymbol       ;
	je isStoppedSymbol          ;         Если этот символ равен            ;
	cmp al, tabulation          ;   пробелу, табуляции, 0Ah, 0Dh или \0
	je isStoppedSymbol          ;     Значит мы дошли до  конца слова
	cmp al, returnSymbol        ;
	je isStoppedSymbol          ;                                        ;
	cmp al, endl                ;
	je isStoppedSymbol          ;
                                ;
	mov es:[di], al             ; Если данный символ входит в слово, добавляем его в результирующую строку
                                ;
	inc di                      ; Увеличиваем di,si т.е. переходим на следующий символ
	inc si                      ;
                                ;
	loop loopParseWord          ; Пока не превышена максимальная длина слова, парсим
isStoppedSymbol:                ;
	mov al, endl          ;
	mov es:[di], al             ; Загружаем символ конца строки в результирующую строку
	inc si                      ; Увеличиваем si для перезода на следующий символ командной строки
                                ;
	pop di                      ; восстанавливаем регистры
	pop cx                      ;
	pop ax                      ;
	ret                         ;
ENDP   
;**************************************************************************************************************************  
  
;*************************************************************************************************************************
;ds:si - смещение, в котором находится начало строки
;Результат - в ax помещается длина строки 
strlen PROC                     ;
	push bx                     ;
	push si                     ;  Сохраняем используемые далее регистры
	                            ;
	xor ax, ax                  ;  Зануляем ax
                                ;
    startCalc:                  ;
	    mov bl, ds:[si]         ;  Загружаем очередной символ строки из ds со смещением si
	    cmp bl, endl            ;  Сравниваем этот символ с символом конца строки
	    je endCalc              ;  Если это символ конца строки - прыгаем в endCalc и заканчиваем вычисления
                                ;
	    inc si                  ;  Увеличиваем si, т.е. переходим к следующему символу
	    inc ax                  ;  Увеличиваем ax, т.е. длину строки                                                     
	    jmp startCalc           ;  Продолжаем
	                            ;
    endCalc:                    ;
	pop si                      ;
	pop bx                      ;  Восстанавливаем значения
	ret                         ;
ENDP                            ;
;*************************************************************************************************************************

;**************************************************************************************************************************
;Результат в ax - 0 если все хорошо
openFiles PROC                  ;
	push bx                     ;
	push dx                     ; Сохраняем значения регистров          
	
	
	;;;;;;;;;
	push si                                     
	                                            
	lea si, sourcePath                          
	call    strlen                              
	    
	xor si, si         
	mov si, ax 
	sub si, 1                   
	        
	cmp sourcePath[si], 't' 
	jne checkTxt_Error     
	
	sub si, 1
	
	cmp sourcePath[si], 'x' 
	jne checkTxt_Error    
	
	sub si, 1
	
	cmp sourcePath[si], 't' 
	jne checkTxt_Error   
	
	sub si, 1
	
	cmp sourcePath[si], '.' 
	jne checkTxt_Error
	                    
	jmp checkTxt_OK                    
	checkTxt_Error: 
	pop si
	jmp badOpenSource       
	       
	checkTxt_OK:                                            ;
	pop si  
	
	;;;;;;;
                                ;
	mov ah, 3Dh			        ; Функция 3Dh - открыть существующий файл
	mov al, 02h			        ; Режим открытия файла
	lea dx, sourcePath          ; Загружаем в dx название исходного файла
	mov cx, 00h			        ; 
	int 21h                     ;
                                ;
	jb badOpenSource	        ; Если файл не открылся, то прыгаем в badOpenSource
                                ;
	mov sourceID, ax	        ; Загружаем в sourceId значение из ax, полученное при открытии файла
                                ;
	mov ax, 0			        ; Загружаем в ax 0, т.е. ошибок во время выполнения процедуры не произшло 
	jmp endOpenProc		        ; Прыгаем в endOpenProc и корректно выходим из процедуры
                                ;
badOpenSource:                  ;
	println badSourceText       ; Выводим соответсвующее сообщение
	cmp ax, 02h                 ; Сравниваем ax с 02h
	jne errorFound              ; Если ax != 02h - файл найден, прыгаем в errorFound
                                ;
	println fileNotFoundText    ; Выводим сообщение о том, что файл не найден 
                                ;
	jmp errorFound              ; Прыгаем в errorFound
                                ;       ;       ==//==                               ;
errorFound:                     ;
	mov ax, 1                   ; Загружаем в ax 1, т.е. произошла ошибка
endOpenProc:                    ;
	pop dx                      ;
	pop bx                      ; Восстанавливаем значения регистров и выходим из процедуры
	ret                         ;
ENDP                            ;
;******************************************************************************************************************************        
 
;**************************************************************************************************************************
closeFiles PROC                 ;
	push bx                     ;
	push cx                     ; Сохраняем значения регистров 
                                ;
	xor cx, cx                  ; Обнуляем cx
                                ;
	mov ah, 3Eh                 ; Загружаем в ah код 3Eh - код закрытия файла
	mov bx, sourceID            ; В bx загружаем ID файла, подлежащего закрытию
	int 21h                     ; Выпоняем прерывание для выполнения 
                                ;
	jnb goodCloseOfSource		; Если ошибок при закрытии не произошло, прыгаем в goodCloseOfSource
                                ;
	println errorClosingSource  ; Иначе выводим соответсвующее сообщение об ошибке       
	                            ;
	inc cx 			            ; now it is a counter of errors
                                ;
goodCloseOfSource:              ;               ;
	mov ax, cx 		            ; Записываем в ax значение из cx, если ошибок не произошло, то это будет 0, иначе 1 или 2, в зависимости от
                                ; количества незакрывшихся файлов
	pop cx                      ;
	pop bx                      ; Восстанавливаем значения регистров и выходим из процедуры
	ret                         ;
ENDP                            ;
;******************************************************************************************************************************
         
;******************************************************************************************************************************       
setPosInFileTo MACRO symbolsInt, symbols;
	push ax                     ;
	push bx                     ;
	push cx                     ;
	push dx                     ; Сохраняем значения регистров
                                ;
	mov ah, 42h                 ; Записываем в ah код 42h - ф-ция DOS уставноки указателя файла
	xor al ,al 			        ; Обнуляем al, т.к. al=0 - код перемещения указателя в начало файла
	mov cx, symbolsInt          ; Обнуляем cx, 
	mov dx, symbols			    ; Обнуляем dx, т.е премещаем указатель на 0 символов от начала файла (cx*2^16)+dx 
	int 21h                     ; Вызываем прерывания DOS для исполнения кодманды   
                                ;
	pop dx                      ; Восстанавливаем значения регистров и выходим из процедуры
	pop cx                      ;
	pop bx                      ;
	pop ax                      ;
ENDM 
;******************************************************************************************************************************

;******************************************************************************************************************************                                ;
divCurrWordIndex MACRO          ;
	mov al, currWordIndex       ; Загружаем в al индекс текущего слова
	xor ah, ah                  ;
                                ;
	push bx                     ; Сохраняем bx
	mov bl, period              ; В bl записываем период, с которым мы удаляем слова, т.е 2
	div bl                      ; Производим деление значения al на bl
	pop bx                      ; Восстанавливаем значение bx; Остаток от деления -> ah, Целая часть -> al
	mov currWordIndex, ah       ; Присваиваем currWordIndex значение остатка от деления, т.е. четное слово или нет 
                                ;
	cmp ah, 0                   ; Сравниваем ah с нулем
	je movToSkip                ; Если ah, т.е остаток от деления на период равен нулю, то пропускаем, т.к. число четное
	jmp movToWrite              ; Иначе прыгаем в movToWrite, где записываем это слово в файл
                                ;
ENDM                            ;
;******************************************************************************************************************************
      
;******************************************************************************************************************************    
processingFile PROC                     ;
	push ax                             ;
	push bx                             ;
	push cx                             ;
	push dx                             ;
	push si                             ;
	push di                             ; Сохраняем значения регистров
                                        ;
	mov bx, sourceID                    ; Загружаем в bx ID файла-источника
	setPosInFileTo 0,0                  ; Вызываем процедую смещения курсора в начало файла
                                        ;
    call readFromFile                   ; Вызов процедуры чтения из файла
	                                    ;
	cmp ax, 0                           ; Сравнивание ah с 0 для проверки на конец файла
	je finishProcessing                 ; Если ah == 0, то буффер пуст и мы дошли до конца файла
                                        ;
	lea si, buffer                      ; Иначе загружаем в si и di смещение буффера
	lea di, buffer                      ;
	mov cx, ax					        ; В cx загружаем ax, т.е кол-во элементов в буффере (кол-во элементов считанных с файла)
	xor dx, dx                          ; Обнуляем dx
                                        ; В dx будет храниться кол-во элементов буффера, подлежащих записи
loopProcessing:                         ;
	                                    ;  
                   ;                    ;
writeDelimsAgain:                       ;
	call writeDelims                    ; После вызова этой ф-ции в bx - кол-во записанных символов, ax - кол-во строк  
	add dx, bx                          ; Добавляем bx к dx, т.е. сколько символов мы записали
	cmp ax, 0                           ; Сравниваем ax с 0, в ax сейчас находится кол-во строк которые мы записали
	je notNewLine                       ; Если ax == 0 прыгаев в notNewLine
                                        ; 
                                        ; Если перезодим на новую строку, то необходимо обнулить индекс текущего слова                   
	mov bl,currWordStartingValue        ; Загружаем в bl индекс слова, с которого начинать удаление
	mov currWordIndex, bl               ; Загружаем в currWordIndex bl
                                        ;
notNewLine:                             ;
	call checkEndBuff                   ; Вызываем процедуру проверки конца буффера, если буффер пуст - подгружаем данные из файла
	cmp ax, 2                           ; Если после вызова процедуры checkEndBuff в ax лежит 2, то заканчиваем обработку - прыгаем в ax
	je finishProcessing                 ; Прыгаем в finishProcessing
	cmp ax, 1                           ; ==//== в ax лежит 1, то буффер был пуст и были подгружены новые данные из файла
	je writeDelimsAgain                 ; Прыгаем в writeDelimsAgain, т.е. 
                                        ;
	divCurrWordIndex                    ; Запускаем макрос, который определяет четное ли слово сейчас или нет
                                        ; и взависимости от этого решает записать слово прыгая в moToWrite, или пропустить слово прыгая в movToSkip
movToWrite:                             ;
	call writeWord                      ; Вызов процедуры записи слова
	add dx, bx                          ; Добавляем в dx bx
	call checkEndBuff                   ; Вызываем процедуру проверки буффера
	cmp ax, 2                           ; Если 2, то заканчиваем обработку, т.е прыгаем в finishProcessing
	je finishProcessing                 ;
	cmp ax, 1                           ; Если 1, то буффер был пустой и были опять подгружены данные
	je movToWrite                       ; Прыгаем обратно в moToWrite. Из этого выход только через ax = 0, т.е когда в буффере что-то есть
                                        ;
	jmp endWriteSkip                    ; Прыгаем в endWriteSkip
                                        ;
movToSkip:                              ;
	call skipWord                       ; bx к dx не добавляем, т.к. эти сиволы мы пропускаем
	call checkEndBuff                   ;
	cmp ax, 2                           ; Тот же алгоритм, только с пропуском слова вместо записи
	je finishProcessing                 ;
	cmp ax, 1                           ;
	je movToSkip                        ;
                                        ;
	jmp endWriteSkip                    ; 
                                        ;
endWriteSkip:                           ;
	push dx                             ; Сохраняем dx
	mov dl, currWordIndex               ; Загружаем в dl номер текущего слова
	inc dl                              ; увеличиваем dl, т.е номер слова
	mov currWordIndex, dl 	            ; Переписываем currWordIndex
	pop dx                              ;
                                        ;
	jmp loopProcessing                  ;
                                        ;
finishProcessing:                       ;
    mov bx, sourceID                    ;                     ;
                                        ;
    setPosInFileTo 0,writedTotal        ; Вызываем прерывания DOS для исполнения кодманды    
                                        ;
    xor ax,ax                           ;
    mov ah, 40h                         ;
    mov bx, sourceID                    ;
    mov cx, 0h                          ;
    int 21h                             ;
                                        ;
	pop di                              ; Восстанавливаем значения 
	pop si                              ;
	pop dx                              ;
	pop cx                              ;
	pop bx                              ;
	pop ax                              ;
	ret                                 ;
ENDP                                    ;
;************************************************************************************************************************** 
  
;**************************************************************************************************************************                
ParseWordAndJumpIfDelimTo MACRO marker  ;  
    cmp al, spaceSymbol                 ;           --------------------
    je marker                           ;                                 
	cmp al, newLineSymbol               ;
	je marker                           ;         Если этот символ равен            
	cmp al, tabulation                  ;    пробелу, табуляции, 0Ah, 0Dh или \0
	je marker                           ;     Значит мы дошли до  конца слова
	cmp al, returnSymbol                ;
	je marker                           ;                                        
	cmp al, endl                        ;
	je marker                           ;           ---------------------
                                        ;
ENDM                                    ;
;**************************************************************************************************************************
                    
;**************************************************************************************************************************       
;ds:si - offset to byte source (will change)
;es:di - offset to byte destination (will change)
;cx - max length (will change)
;RES
;	bx - кол-во записываемых символов, т.е. разделителей
;	ax - кол-во переходов на новую строку
writeDelims PROC                        ;
	push dx                             ; Сохраняем значение регистра dx
	xor bx, bx                          ; Обнуляем dx и bx
	xor dx, dx                          ; bx - количество записанных символов, dx- количество перехоов на новую строку
                                        ;
startWriteDelimsLoop:                   ;
	mov al, ds:[si]                     ; Записываем в al символ, подлежащий записи
	                                    ;
	cmp al, spaceSymbol                 ;            -------------------
    je isDelim                          ;
                                        ;
	cmp al, newLineSymbol               ;
	je isNewLineSymbol                  ;         Если этот символ равен
                                        ;
	cmp al, tabulation                  ;   пробелу, табуляции, 0Ah, 0Dh или \0
	je isDelim                          ;
                                        ;     Значит мы дошли до  конца слова
	cmp al, returnSymbol                ;
	je isNewLineSymbol                  ;
                                        ;
	cmp al, endl                        ;
	je isDelim                          ;           ---------------------
                                        ;                                       ;
	jmp isNotDelim                      ; Иначе прыгаем в isNotDelim
                                        ;
isNewLineSymbol:                        ;
	inc dx                              ; Увеличиваем dx, т.к. в dx храниться кол-во переходов на новую строку
isDelim:                                ;
	movsb                               ; Записываем в ячейку ES:DI байт из ячейки DS:SI
	inc bx                              ; Увеличиваем bx, т.е. кол-во записанных символов
	loop startWriteDelimsLoop           ;
                                        ;
isNotDelim:                             ;
	mov ax, dx                          ; Загружаем dx в ax
                                        ;
	pop dx                              ; Восстанавливаем значение регистра dx и выходим из процедуры
	ret                                 ;
ENDP                                    ;
;****************************************************************************************************************************
                
;****************************************************************************************************************************
;ds:si - offset, where we will find (will change)
;es:di - offset, where word will be (will change)
;cx - кол-во необработанных сивмолов буффера
;bx - кол-во записываемых символов
writeWord PROC                      ;
	push ax                         ; Сохраняем 
	xor bx, bx                      ; Обнуляем bx
                                    ;
loopParseWordWW:                    ;
	mov al, ds:[si]                 ; Загружаем в al текущий символ
	
	ParseWordAndJumpIfDelimTo isStoppedSymbolWW
                                    ;
	movsb                           ;
	inc bx                          ;
	loop loopParseWordWW            ;
                                    ;
isStoppedSymbolWW:                  ;
	pop ax                          ;
	ret                             ;
ENDP
;*****************************************************************************************************************************          
    
;*****************************************************************************************************************************          
;ds:si - offset, where we will find (will change)
;То же самое, что и в writeWord
skipWord PROC
	push ax
	xor bx, bx
	
loopParseWordSW:
	mov al, ds:[si]
	
	ParseWordAndJumpIfDelimTo isStoppedSymbolSW

	inc si
	inc bx
	loop loopParseWordSW

isStoppedSymbolSW:
	pop ax
	ret
ENDP  
;*****************************************************************************************************************************
   
;*****************************************************************************************************************************   
;reads to buffer maxWordSize symbols
;Результат: в ax помещается колв-во считанных из файла символов
readFromFile PROC                   ;
	push bx                         ;
	push cx                         ;
	push dx                         ; Сохраняем значения регистров
                                    ;
	mov ah, 3Fh                     ; Загружаем в ah код 3Fh - код ф-ции чтения из файла
	mov bx, sourceID                ; В bx загружаем ID файла, из которого собираемся считывать
	mov cx, maxWordSize             ; В cx загружаем максимальный размер слова, т.е. считываем максимальное кол-во символов (maxWordSize символов)
	lea dx, buffer                  ; В dx загружаем смещения буффера, в который будет считывать данные из файла
	int 21h                         ; Вызываем прерывание для выполнения ф-ции
                                    ;
	jnb goodRead					; Если ошибок во время счтения не произошло - прыгаем в goodRead
                                    ;
	println errorReadSourceText     ; Иначе выводим сообщение об ошибке чтения из файла
	mov ax, 0                       ; Записываем в ax 0
                                    ;
goodRead:                           ;   
    add readedTotal, ax                                ;
	pop dx                          ; Восстанавливаем значения регистров
	pop cx                          ;
	pop bx                          ;
	ret                             ;
ENDP                                ;
;*****************************************************************************************************************************
             
;*****************************************************************************************************************************             
;cx - кол-во записываемых символов от начала буффера
;RES: ax - number of writed bytes
writeToFile PROC                      ;
	push bx                           ;
	push cx                           ;
	push dx                           ; Сохраняем значения регистров  
	                                  ;
	mov bx, sourceID                  ;
	setPosInFileTo 0, writedTotal     ;
	                                  ;
	add writedTotal, cx               ;                        
	                ;                 ;
	mov ah, 40h                       ; Загружаем в ah код 40h - код ф-ции записи в файл
	mov bx, sourceID                  ; В bx загружаем ID файла, в который будем записывать данные
	lea dx, buffer                    ; В dx загружаем данные, которые будет записывать
	int 21h                           ; Вызываем прерывание для выполения команды
                                      ;
	jnb goodWrite					  ; Если во время записи ошибок не произошло, прыгаем в goodWrite
                                      ;
	println errorWritingText          ; Иначе выводим сообщение о возникновении ошибки при записи
	mov ax, 0                         ; Обнуляем ax
                                      ;
goodWrite:                            ;
    mov bx, sourceID                  ;                 
    setPosInFileTo 0, readedTotal     ;
                                      ;
	pop dx                            ; Восстанавливаем регистры и выхоидм из процедуры
	pop cx                            ;
	pop bx                            ;
	ret                               ;
ENDP                                  ;
;******************************************************************************************************************************
               
;******************************************************************************************************************************               
;Результат: помещает в ax -
;	ax = 0 - буффер еще не пуст, т.е. еще есть данные для обработки
;	ax = 1 - буффер был обработан, данные записаны, и новый "кусок" файла был подгружен в буффер 
;	ax = 2 - буффер был обработан, данные записаны, была совершена попытка подгузки данных, но программа уже дошла до конца файла
checkEndBuff PROC               ;
	cmp cx, 0                   ; Сравниваем cx с нулем
	jne notEndOfBuffer          ; Если cx != 0, то буффер еще не полностью записан, прыгаем в notEndOfBuffer
                                ;
	cmp dx, 0                   ; Сравниваем dx и 0
	je skipWrite                ; Если dx == 0, то нам нечего записывать, поэтому прыгаем в skipWrite
	                            ; Если буффер не пустой и есть что записывать
	mov cx, dx                  ; Записывает в cx dx, т.е. кол-во символов, которые надо записать, которое храниться в dx в результате оперции writeWord
	call writeToFile            ; Вызываем ф-цию записи в файл
                                ;
skipWrite:                      ;
	call readFromFile           ; Считываем часть файла
	cmp ax, 0                   ; Сравниваем ax с нулем, если ax == 0, то произошла ошибка, соответсвенно переходим в endOfProcessing
	je endOfProcessing          ;
                                ;
	lea si, buffer              ; Загружаем в si и di смещение буффера, в который считывали данные из файла
	lea di, buffer              ;
	mov cx, ax					; Записываем в cx кол-во символов в буффере из ax
	xor dx, dx                  ; Обнуляем dx
                                ;
	mov ax, 1                   ; Записываем в ax - конец буффера
	ret                         ;
                                ;
endOfProcessing:                ;
	mov ax, 2                   ; Конец обработки - помещаем в ax условный код 2
	ret                         ;
                                ;
notEndOfBuffer:                 ;
	mov ax, 0                   ; Если чтение еще не окончено - записываем условный код 0
	ret                         ;
ENDP                            ;
;*******************************************************************************************************************************

end main
;???? "??????"


;macro HELP
endd MACRO
	mov ah, 4ch
	int 21h
ENDM

clearScreen MACRO          ;
	push ax                ; Сохраняем значение ax
	mov ax, 0003h          ; 00 - установить видеорежим, очистить экран. 03h - режим 80x25
	int 10h                ; Вызов прерывания для исполнения команды
	pop ax                 ; Восстанавливаем значение регистра ax
ENDM                       ;
;end macro help

.model small

.stack 100h

.data

;key bindings (configuration)
KUpSpeed    equ 48h	;Up key
KDownSpeed  equ 50h	;Down key
KMoveUp     equ 11h	;W key
KMoveDown   equ 1Fh	;S key
KMoveLeft   equ 1Eh	;A key
KMoveRight  equ 20h	;D key
KExit       equ 01h ;ESC key

xSize equ 80
ySize equ 25
xField equ 50
yField equ 21
oneMemoBlock equ 2
scoreSize equ 4

videoStart dw 0B800h
dataStart dw 0000h
timeStart dw 0040h
timePosition dw 006Ch

space equ 0020h
snakeBodySymbol equ 0A40h
appleSymbol equ 0B0Fh
VWallSymbol equ 0FBAh
HWallSymbol equ 0FCDh
VWallSpecialSymbol equ 0FCCh

fieldSpacingBad equ space, VWallSymbol, xField dup(space)
fieldSpacing equ fieldSpacingBad, VWallSymbol
rbSym equ 0CFDCh	;white block with red background
rbSpc equ 0CF20h	;space with red background
ylSym equ 06FDCh	;white block with yellow background
ylSpc equ 06F20h	;space with yellow background
grSym equ 02FDBh	;white block with green background
grSpc equ 02F20h	;space with green background

screen	dw xSize dup(space)
		dw space, 0FC9h, xField dup(HWallSymbol), 0FCBh, xSize - xField - 5 dup(HWallSymbol), 0FBBh, space
firstBl	dw fieldSpacing, xSize - xField - 5 dup(rbSpc), VWallSymbol, space
		dw fieldSpacing, rbSpc, 4 dup(rbSym), 15 dup(rbSpc), 4 dup(rbSym), rbSpc, VWallSymbol, space
		dw fieldSpacing, rbSpc, rbSym, 5 dup(rbSpc), 3 dup(rbSym), 2 dup(rbSpc), 3 dup(rbSym), rbSpc, rbSym, 3 dup(rbSpc), rbSym, 2 dup(rbSpc), rbSym, rbSpc, VWallSymbol, space
		dw fieldSpacing, rbSpc, 4 dup(rbSym), rbSpc, rbSym, 2 dup(rbSpc), rbSym, rbSpc, rbSym, 2 dup(rbSpc), 3 dup(rbSym, rbSpc), 4 dup(rbSym), rbSpc, VWallSymbol, space
		dw fieldSpacing, 4 dup(rbSpc), rbSym, rbSpc, rbSym, 2 dup(rbSpc), rbSym, rbSpc, 4 dup(rbSym), rbSpc, 2 dup(rbSym), 2 dup(rbSpc), rbSym, 4 dup(rbSpc), VWallSymbol, space
		dw fieldSpacing, rbSpc, 4 dup(rbSym), rbSpc, rbSym, 2 dup(rbSpc), rbSym, rbSpc, rbSym, 2 dup(rbSpc), 3 dup(rbSym, rbSpc), 4 dup(rbSym), rbSpc, VWallSymbol, space
		dw fieldSpacing, xSize - xField - 5 dup(rbSpc), VWallSymbol, space
delim1	dw fieldSpacingBad, 0FCCh, xSize - xField - 5 dup(HWallSymbol), 0FB9h, space
secondF	dw fieldSpacing, xSize - xField - 5 dup(ylSpc), VWallSymbol, space
		dw fieldSpacing, ylSpc, 06F53h, 06F63h, 06F6Fh, 06F72h, 06F65h, 06F3Ah, ylSpc
	score	dw scoreSize dup(06F30h), xSize - xField - scoreSize - 13 dup(ylSpc), VWallSymbol, space
		dw fieldSpacing, xSize - xField - 5 dup(ylSpc), VWallSymbol, space
		dw fieldSpacing, ylSpc, 06F53h, 06F70h, 2 dup(06F65h), 06F64h, 06F3Ah, ylSpc
	speed	dw 06F31h, 16 dup(ylSpc), VWallSymbol, space
		dw fieldSpacing, xSize - xField - 5 dup(ylSpc), VWallSymbol, space
delim2	dw fieldSpacingBad, 0FCCh, xSize - xField - 5 dup(HWallSymbol), 0FB9h, space
thirdF	dw fieldSpacing, xSize - xField - 5 dup(grSpc), VWallSymbol, space
		dw fieldSpacing, grSpc, 02F4Dh, 02F61h, 02F64h, 02F65h, grSpc, 02F62h, 02F79h, 02F3Ah, 10 dup(grSpc), 02FDCh, 3 dup(grSym), 02FDCh, grSpc, VWallSymbol, space
		dw fieldSpacing, 19 dup(grSpc), grSym, 02FDDh, grSym, 02FDEh, grSym, grSpc, VWallSymbol, space
		dw fieldSpacing, 2 dup(grSpc), 02FDCh, 02FDFh, grSym, 2 dup(grSpc), 2 dup(grSym, grSpc), 02FDEh, 2 dup(grSym), grSpc, grSym, 02FDFh, 02FDDh, grSpc, 5 dup(grSym), grSpc, VWallSymbol, space
		dw fieldSpacing, 2 dup(grSpc), grSym, 02FDCh, grSym, 2 dup(grSpc), 4 dup(grSym, grSpc), grSym, 02FDFh, 02FDCh, grSpc, grSym, grSpc, 02FDFh, grSpc, grSym, grSpc, VWallSymbol, space
		dw fieldSpacing, grSpc, 2 dup(02FDCh, 2 dup(grSym, grSpc)), 2 dup(grSym), 02FDDh, grSpc, grSym, 02FDCh, grSym, grSpc, 02FDFh, grSym, 02FDCh, grSym, 02FDFh, grSpc, VWallSymbol, space
		dw fieldSpacing, xSize - xField - 5 dup(grSpc), VWallSymbol, space
		dw space, 0FC8h, xField dup(HWallSymbol), 0FCAh, xSize - xField - 5 dup(HWallSymbol), 0FBCh, space
		dw xSize dup(space)

snakeMaxSize equ 20
snakeSize db 2
PointSize equ 2

; XYh coordinates
; first position - head
snakeBody dw 1C0Ch, 1B0Ch, snakeMaxSize-1 dup(0000h)

stopVal equ 00h
forwardVal equ 01h
backwardVal equ 0FFh

Bmoveright db 01h
Bmovedown db 00h

minWaitTime equ 1
maxWaitTime equ 9
waitTime dw maxWaitTime
deltaTime equ 2

.code

main:
	mov ax, @data	        ;init
	mov ds, ax              ;
	mov dataStart, ax       ; Загружаем начальные данные
	mov ax, videoStart      ; Загружаем в ax код начала вывода в видеобуффер
	mov es, ax              ; Загружаем ax в es
	xor ax, ax              ; Обнуляем ax
                            ;
	clearScreen             ; Очищаем консоль
                            ;
	call initAllScreen      ; Инициализируем экран
                            ;
	call mainGame           ; Переходим в основной цикл игры
                            ;
to_close:                   ;
	;clearScreen            ;
                            ;
	endd                    ;
                            ;
;more macro help            ;
                            ;
;ZF = 1 - buffer is free    ;
;AH = scan-code             ;
CheckBuffer MACRO           ; Проверяем - был ли введен символ с клавиатуры
	mov ah, 01h             ;   
	int 16h                 ;
ENDM                        ;
                            ;
ReadFromBuffer MACRO        ; Считываем нажатую клавишу
	mov ah, 00h             ;
	int 16h                 ;
ENDM                        ;
                            ;
;result in cx:dx            ;
GetTimerValue MACRO         ;
	push ax                 ;
                            ;
	mov ax, 00h             ;
	int 1Ah                 ;
                            ;
	pop ax                  ;
ENDM                        ;
                            ;
;end macro help
                        ;
;procedure help         ;
                        ;
initAllScreen PROC      ;
	mov si, offset screen   ; В si загружаем 
	xor di, di              ; Обнуляем di
                            ; Теперь ds:si указывает на символы, которые мы будет выводить
                            ; а es:di на di'ый символ консоли 
	mov cx, xSize*ySize     ; Загружаем в cx кол-во символов в консоли, т.е. 80x25                                    
	rep movsw               ; Переписываем последовательно все cx символов из ds:si в консоль es:di 
                            ;
                            ;
	xor ch, ch              ; Обнуляем ch
	mov cl, snakeSize       ; Загружаем в cl размер змейки
	mov si, offset snakeBody; В si загружаем смещения начала тела змейки
                            ;
loopInitSnake:              ; Цикл, в котором мы выводим тело змейки
	mov bx, [si]            ; Загружаем в si очередной символ тела змейки
	add si, PointSize       ; Добавляем к si PointSize, т.е. 2, т.к. каждая точка занимает 2 байта (цвет + символ)
	
	;get pos as (bh + (bl * xSize))*oneMemoBlock
	call CalcOffsetByPoint  ; Получаем смещение выводимого символа в видеобуффере
                            ;
	mov di, bx              ; загружаем в di позицию
                            ;
	mov ax, snakeBodySymbol ; Загружаем в ax выводимый символ
	stosw                   ; Выводим
	loop loopInitSnake      ;
                            ;
	call GenerateRandomApple; Генерируем яблоко в случайных координатах
                            ;
	ret                     ;
ENDP                        ;

;get pos as (bh + (bl * xSize))*oneMemoBlock
;input: point (x,y) in bx
;output: offset in bx
CalcOffsetByPoint PROC      ;    
	push ax                 ; Сохраняем значения регистров ax и dx
	push dx                 ;
	                        ;
	xor ah, ah              ; Обнуляем ah
	mov al, bl              ; Загружаем в al bl
	mov dl, xSize           ; В dl загружаем xSize - размер строки
	mul dl                  ; Умножаем al на dl
	mov dl, bh              ; Загружаем в dl bh
	xor dh, dh              ; Обнуляем dh
	add ax, dx              ; Добавляем к ax dx
	mov dx, oneMemoBlock	; Загружаем в dx oneMemoBlock - длину каждого блока
	mul dx                  ; Умножаем на размер блока
	mov bx, ax              ; Загружаем ax в bx
                            ;
	pop dx                  ; Восстанавливаем значения регистров dx и ax
	pop ax                  ;
	ret                     ;
ENDP                        ;

;change snake body in array
;old last element is always saved
;delete old last element from screen
MoveSnake PROC              ;
	push ax                 ;
	push bx                 ;
	push cx                 ;
	push si                 ; Сохраняем значения регистров
	push di                 ;
	push es                 ;
                            ;
	mov al, snakeSize       ; В al загружаем длину змейки
	xor ah, ah 		        ; Обнуляем ah
	mov cx, ax 		        ; Загружаем в cx ax
	mov bx, PointSize       ; Загружаем в bx размер точки на экране
	mul bx			        ; Теперь в ax реальная позиция в памяти относительно начала массива
	mov di, offset snakeBody; Загружаем в di смещение тела змейки
	add di, ax 		        ; di - адрес следующего после последнего элемента массива
	mov si, di              ; Загружаем di в si
	sub si, PointSize 	    ; si - адрес последнего элемента массива
                            ;
	push di                 ; Сохраняем значение di
	                        ; Удаляем конец змейки с экрана
	mov es, videoStart      ; Загружаем в es смещение видеобуффера
	mov bx, ds:[si]         ; Загружаем в bx последний элемент змейки
	call CalcOffsetByPoint  ; Вычисляем ее позицию на экране
	mov di, bx			    ; Заносим позицию, которую будем очищать в di
	mov ax, space           ; Загружаем в ax пустую клетку
	stosw                   ; Записываем
                            ;
	pop di                  ; Восстанавливаем di
                            ;
	mov es, dataStart	    ; Для работы с данными
	std				        ; Идем от конца к началу
	rep movsw               ;
                            ;
	mov bx, snakeBody 	    ; Загружаем в bx текущую позицию головы
                            ;
	add bh, Bmoveright      ; Обновляем координаты головы
	add bl, Bmovedown	    ; 
	mov snakeBody, bx	    ; сохраняем новую позицию головы
	                        ; 
	                        ; теперь все тело в памяти сдвинуто                           ;
	pop es                  ;
	pop di                  ;
	pop si                  ;
	pop cx                  ; Восстанавливаем значения регистров
	pop bx                  ;
	pop ax                  ;
	ret                     ;
ENDP                        ;

mainGame PROC
	push ax                      ;
	push bx                      ;
	push cx                      ;
	push dx                      ; Сохраняем значения регистров
	push ds                      ;
	push es                      ;
                                 ;
checkAndMoveLoop:                ;
	                             ;
	CheckBuffer                  ; Проверяем - был ли введен символ
	jnz skipJmp2                 ; Если да - skipJmp2
	jmp far ptr noSymbolInBuff   ; Иначе noSymbolInBuff
                                 ;
skipJmp2:                        ;
	ReadFromBuffer               ; Считываем символ из буффера
                                 ;
	cmp ah, KExit		         ; Если была нажата кнопка выхода
	jne skipJmp                  ; Иначе skipJmp
                                 ;
	jmp far ptr endLoop          ; Заканчиваем игру, прыгая в endLoop
                                 ;
skipJmp:                         ;
	cmp ah, KMoveLeft	         ; Если была нажата кнопка "влево"
	je setMoveLeft               ;
                                 ;
	cmp ah, KMoveRight	         ; Если была нажата кнопка "вправо"
	je setMoveRight              ;
                                 ;
	cmp ah, KMoveUp		         ; Если была нажата кнопка "вверх"
	je setMoveUp                 ;
                                 ;
	cmp ah, KMoveDown	         ; Если была нажата кнопка "вниз"
	je setMoveDown               ;
                                 ;
	cmp ah, KUpSpeed		     ; move up key is pressed
	je setSpeedUp                ;
                                 ;
	cmp ah, KDownSpeed	         ; move down key is pressed
	je setSpeedDown              ;
                                 ;
	jmp noSymbolInBuff           ;
                                 ;
setMoveLeft:                     ;
	mov Bmoveright, backwardVal  ; Направление вправо - отрицательное
	mov Bmovedown,  stopVal      ; Направление вниз - нулевое
	jmp noSymbolInBuff           ;
                                 ;
setMoveRight:                    ;
	mov Bmoveright, forwardVal   ; Направление вправо - положительное
	mov Bmovedown, stopVal       ; Направление вправо - нулевое
	jmp noSymbolInBuff           ;
                                 ;
setMoveUp:                       ; Направление вправо - нулевое
	mov Bmoveright, stopVal      ; Направление вниз - отрицательное
	mov Bmovedown, backwardVal   ;
	jmp noSymbolInBuff           ;
                                 ;
setMoveDown:                     ;
	mov Bmoveright, stopVal      ; Направление вправо - нулевое
	mov Bmovedown, forwardVal    ; Направление вниз - положительное
	jmp noSymbolInBuff           ;
                                 ;
setSpeedUp:                      ;
	mov ax, waitTime             ;
	cmp ax, minWaitTime          ;
	je noSymbolInBuff			 ;?????? ????;?? ????????? ????? ????????
	                             ;
	sub ax, deltaTime            ;
	mov waitTime, ax 			 ;???????? ??;??? ???????? ????????
                                 ;
	mov es, videoStart           ;
	mov di, offset speed - offset screen	;???????? ???????? ??????? ????????
	mov ax, es:[di]              ;
	inc ax                       ;
	mov es:[di], ax              ;
                                 ;
	jmp noSymbolInBuff           ;
                                 ;
setSpeedDown:                    ;
	mov ax, waitTime             ;
	cmp ax, maxWaitTime          ;
	je noSymbolInBuff			 ;?????? ???;??? ??????????? ????? ????????
	                             ;
	add ax, deltaTime            ;
	mov waitTime, ax 			 ;???????? ?;???? ???????? ????????
                                 ;
	mov es, videoStart           ;
	mov di, offset speed - offset screen	;???????? ???????? ??????? ????????
	mov ax, es:[di]              ;
	dec ax                       ;
	mov es:[di], ax              ;
                                 ;
	jmp noSymbolInBuff           ;
                                 ;
noSymbolInBuff:                  ;
	call MoveSnake               ; Передвигаем змейку на экране
                                 ;
	mov bx, snakeBody 		     ; В bx голова змеи
checkSymbolAgain:                ;
	call CalcOffsetByPoint	     ; В bx смещение памяти, соответствующее точке
                                 ;
	mov es, videoStart           ; Загружаем в es смещение видеобуффера
	mov ax, es:[bx]		         ; Загружаем в ax символ куда должна стать змейка
                                 ;
	cmp ax, appleSymbol          ; Если этот символ - яблоко
	je AppleIsNext               ;
                                 ;
	cmp ax, snakeBodySymbol      ; Если этот символ - тело змейки
	je SnakeIsNext               ;
                                 ;
	cmp ax, HWallSymbol          ; Если этот символ - горизонтальная стена
	je PortalUpDown              ;
                                 ; 
	cmp ax, VWallSymbol          ; Если этот символ - верникальная стена
	je PortalLeftRight           ;
                                 ;
	cmp ax, VWallSpecialSymbol   ; 
	je PortalLeftRight           ;
                                 ;
	jmp GoNextIteration          ;
                                 ;
AppleIsNext:                     ;
	call incSnake                ; Увеличиваем длину змейки
	call GenerateRandomApple     ; Генерируем новое яблоко
	call incScore                ; Увеличиваем счет
	jmp GoNextIteration          ; Переходим к следующей итерации
SnakeIsNext:                     ;
	call incSnake                ;
	jmp endLoop                  ; Заканчиваем игру
PortalUpDown:                    ;
	mov bx, snakeBody            ; Загружаем в bx голову змейки
	sub bl, yField               ; Отнимаем от y координаты высоту консоли 
	cmp bl, 0		             ; Определяем верхняя это или нижняя граница
	jg writeNewHeadPos           ; Перерисовываем голову змейки
                                 ;
	                             ; Если это была верхняя стена
	add bl, yField*2             ; Корректируем координаты 
                                 ;
writeNewHeadPos:                 ;
	mov snakeBody, bx	         ; Записываем новое значение головы
	jmp checkSymbolAgain	     ; и отправляем его заново на сравнение
                                 ;
PortalLeftRight:                 ;
	mov bx, snakeBody            ;
	sub bh, xField               ;
	cmp bh, 0		             ; 
	jg writeNewHeadPos           ;  Аналогично обрабатываем случай с вертикальной стеной
                                 ;
	add bh, xField*2             ;
	jmp writeNewHeadPos          ;
                                 ;
GoNextIteration:                 ;
	mov bx, snakeBody		     ; Загружаем в bx новое начало змейки
	call CalcOffsetByPoint       ; Вычисляем ее позицию
	mov di, bx                   ; Теперь в di смещение позиции bx в консоли
	mov ax, snakeBodySymbol      ; Записываем в ax символ змейки 
	stosw                        ; Записываем в консоль
                                 ;
	call Sleep                   ; Задержка
                                 ;
	jmp checkAndMoveLoop         ;
                                 ;
endLoop:                         ;
	pop es                       ;
	pop ds                       ;
	pop dx                       ; Восстанавливаем значения регистров
	pop cx                       ;
	pop bx                       ;
	pop ax                       ;
	ret                          ;
ENDP                             ;
                                 ;
Sleep PROC                       ;
	push ax                      ;
	push bx                      ; Сохраняем регистры
	push cx                      ;
	push dx                      ;
                                 ;
	GetTimerValue                ; Получаем текущее значение времени
                                 ;
	add dx, waitTime             ; Добавляем к dx значение задержки
	mov bx, dx                   ; Загружаем его в bx
                                 ;
checkTimeLoop:                   ;
	GetTimerValue                ; Получаем текузее значение времени
	cmp dx, bx			         ; ax - current value, bx - needed value
	jl checkTimeLoop             ; Если еще рано - уходим на следующую итерацию 
                                 ;
	pop dx                       ;
	pop cx                       ;
	pop bx                       ; Восстанавливаем значения регистров
	pop ax                       ;
	ret                          ;
ENDP                             ;

GenerateRandomApple PROC  ;
	push ax               ;
	push bx               ;
	push cx               ; Сохраняем значения регистров
	push dx               ;
	push es               ;
	                      ;
loop_random:              ;
	mov ah, 2Ch           ; Считываем текущее время
	int 21h               ; ch - час, cl - минуты, dh - секунды, dl - мсек
                          ;
	mov al, dl            ; Получаем случайное число
	mul dh 				  ; Теперь в ax число для рандома
                          ;
	xor dx, dx			  ; Обнуляем dx
	mov cx, xField        ; В cx загружаем ширину поля
	div cx				  ; Получаем номер строки яблока
	add dx, 2			  ; Добавляем смещение от начала оси
	mov bh, dl 		      ; Сохраняем координату x
                          ;
	xor dx, dx            ;
	mov cx, yField        ;
	div cx                ; Аналогично получаем y координату
	add dx, 2			  ;
	mov bl, dl 			  ; Теперь в bx находится координата яблока
                          ;
	call CalcOffsetByPoint; Расситываем смещение
	mov es, videoStart    ; Загружаем в es начало видеобуффера
	mov ax, es:[bx]       ; В ax загружаем символ, который расположен по координатам, в которых мы хотим расположить яблоко
                          ;
	cmp ax, space         ; Сравниваем их с пробелом(т.е. пустой клеткой). 
	jne loop_random		  ; Если в клетке что-то есть - генерируем новые координаты
                          ;
	mov ax, appleSymbol   ; Загружаем в ax символ яблока
	mov es:[bx], ax       ; Выводим символ яблока
                          ;
	pop es                ;
	pop dx                ;
	pop cx                ; Восстанавливаем регистры
	pop bx                ;
	pop ax                ;
	ret                   ;
ENDP                      ;

;save tail of snake if no overloading
incSnake PROC
	push ax
	push bx
	push di
	push es

	mov al, snakeSize
	cmp al, snakeMaxSize
	je return

	;??????????? ????? ?????? ? ???????
	inc al
	mov snakeSize, al
	dec al 				;??? ??? ?????????? ?????? ??????? ?????? ????? ??????

	;??????????????? ?????
	mov bl, PointSize
	mul bl 				; ???????? ? ax ?????? ??? ?????????????? ???????? ? ???????

	mov di, offset snakeBody
	add di, ax 			;di ????????? ?? ????? ??? "??????????????"

	mov es, dataStart
	mov bx, es:[di]
	call CalcOffsetByPoint		;???????? ???????? ???????? ??? ??????????????

	mov es, videoStart
	mov es:[bx], snakeBodySymbol
	
return:
	pop es
	pop di
	pop bx
	pop ax
	ret
ENDP

incScore PROC
	push ax
	push es
	push si
	push di
	mov es, videoStart
	mov cx, scoreSize 					;max pos value
	mov di, offset score + (scoreSize - 1)*oneMemoBlock - offset screen	;???????? ???????? ?????????? ??????? ?????

loop_score:	
	mov ax, es:[di]
	cmp al, 39h			;'9' symbol
	jne nineNotNow
	
	sub al, 9			;?????? '0'
	mov es:[di], ax

	sub di, oneMemoBlock	;return to symbol back

	loop loop_score
	jmp return_incScore

nineNotNow:
	inc ax
	mov es:[di], ax
return_incScore:
	pop di
	pop si
	pop es
	pop ax
	ret
ENDP

;end procedure help

end main
;Параметры 1, 2, 3: время начала (часы, минуты, секунды)
;Параметры 4, 5, 6: длительность (часы, минуты, секунды)
.model tiny                ;
.code                      ;
	org 100h               ; Размер PSP
                           ;
start:                     ;
	jmp main               ;
                           ;
;data                      ;
startHour       db 0       ;
startMinutes    db 0       ; Время начала
startSeconds    db 0       ;
                           ;
durationHour    db 0       ; 
durationMinutes db 0       ; Продолжительность сигнала
durationSeconds db 0       ;
                           ;
stopHour        db 0       ;
stopMinutes     db 0       ; Время в прекращения вывода сигнала
stopSeconds     db 0       ;
                           
badCMDArgsMessage db "Bad command-line arguments. I want only 6 arguments: start time (hour, minute, second) and duration time (hour, minute, second)", '$'
 
isAlarmOn db 0
                           
;**********************************************************************************************************************
;                                                        BANNER
;**********************************************************************************************************************                           
widthOfBanner   equ 40     ; Ширина выводимого баннера
allWidth        equ 80     ; Полная ширина консоли DOS-box
red             equ 4020h  ;
white           equ 7020h  ; Цвета + выводимые символы. 4020h : 40 - код красного цвета, 20 - код символа залитого прямоугольника
black           equ 0020h  ;

wakeUpText 	dw widthOfBanner dup(red)
			dw 4 dup(red), white, 5 dup(red), white, 2 dup(red), 2 dup(white), red, white, red, 2 dup(white), red, 3 dup(white), 4 dup(red), white, 2 dup(red), white, red, 3 dup(white), 4 dup(red)
			dw 4 dup(red), white, 5 dup(red), 5 dup(white, red), red, white, 6 dup(red), white, 2 dup(red), 3 dup(white, red), 3 dup(red)
			dw 5 dup(red), 3 dup(white, red), red, 3 dup(white), red, 2 dup(white), 3 dup(red), 2 dup(white), 5 dup(red), white, 2 dup(red), white, red, 3 dup(white), 4 dup(red)
			dw 5 dup(red), 3 dup(white, red), 4 dup(red, white), 2 dup(red), white, 6 dup(red), white, 2 dup(red), 2 dup(white, red), 5 dup(red)
			dw 6 dup(red), 2 dup(white, red), 2 dup(red), 3 dup(white, red), 2 dup(white), red, 3 dup(white), 5 dup(red), 2 dup(white), 2 dup(red), white, 6 dup(red)
			dw widthOfBanner dup(red)

offWakeUp	dw widthOfBanner dup(black)
			dw widthOfBanner dup(black)
			dw widthOfBanner dup(black)
			dw widthOfBanner dup(black) ; Сплошной баннер из черного цвета, который отобразиться поверх оповещения будильника, 
			dw widthOfBanner dup(black) ; чтобы его закрасить, когда его необходимо убрать
			dw widthOfBanner dup(black)
			dw widthOfBanner dup(black)     
;**********************************************************************************************************************
;                                                     END  BANNER
;**********************************************************************************************************************
                                      ;
intOldHandler dd 0                    ;
                                      ;
handler PROC                          ; Новый обработчик прерывания
	pushf                             ;
	                                  ;
	call cs:intOldHandler             ; Вызываем старный обработчик прерывания
	push ds                           ;
    push es                           ;
	push ax                           ;
	push bx                           ; Сохраняем регистры
    push cx                           ;
    push dx                           ;
	push di                           ;
                                      ;
	push cs                           ;
	pop ds                            ;
                                      ;
	mov ah, 02h                       ;	02H ¦AT¦ читать время из "постоянных" (CMOS) часов реального времени
	int 1Ah                           ;   выход: CH = часы в коде BCD   (пример: CX = 1243H = 12:43) 
	                                  ;          CL = минуты в коде BCD
                                      ;          DH = секунды в коде BCD
                                      ;   выход: CF = 1, если часы не работают
	                                  ; 
	cmp ch, startHour                 ; проверка на возможность включения будильника
	jne stopCheck                     ;
	cmp cl, startMinutes              ; Если текущее время не равно времени срабатывания будильника - прекращаем проверку 
	jne stopCheck                     ;
	cmp dh, startSeconds              ;
	jne stopCheck                     ;
	                                  ;
	                                  ; Определяем текущее состояние будильника
	mov dl, isAlarmOn                 ; Если буульник не включен - прекращаем проверку
	cmp dl, 0                         ;
	jne stopCheck                     ;
                                      ;
	                                  ; here => start alarm
	mov si, offset wakeUpText         ; Загружаем в si необходимое сообщение
	call printBanner                  ; Вызываем вывод сообщения, находящегося в si
	mov dl, 1                         ; 
	mov isAlarmOn, dl                 ; Устанавливаем состояние будильника в 1
                                      ; Заканчиваем обработку
	jmp endHandler                    ;
                                      ;
stopCheck:                            ; Проверка на возможность выключения будильника
	cmp ch, stopHour                  ;
	jne endHandler                    ;
	cmp cl, stopMinutes               ; Если текущее время != время выключения - прекращаем проверку
	jne endHandler                    ;
	cmp dh, stopSeconds               ;
	jne endHandler                    ;
 	                                  ; Определяем текущее состояние будильника
	mov dl, isAlarmOn                 ;
	cmp dl, 1                         ; Если будильник не включен - заканчиваем проверку 
	jne endHandler                    ;
                                      ;
	                                  ; 
	mov si, offset offWakeUp          ; Убираем сообщение будильника
	call printBanner                  ; Загружаем в si, сообщение, скрывающее оповещение "Wake Up"
	mov dl, 0                         ;
	mov isAlarmOn, dl                 ; Устанавливаем состояние будильника в 0
                                      ;
endHandler:                           ;
	pop di                            ;
	pop dx                            ;
	pop cx                            ;
	pop bx                            ; Восстанавливаем регистры
	pop ax                            ;
	pop es                            ;
	pop ds	                          ;
	iret                              ;
ENDP                                  ;
                                      ;	
printBanner PROC                      ; Процедура вывода баннера
	push es                           ; В si находится смещение выводимого сообщения
	push 0B800h                       ; Загружаем в 16-битный регистр данных
                                      ; 0b800h соответствует сегменту дисплея в тестовом режиме
	pop es                            ; ES=0B800h
                                      ;
	mov di, 9*allWidth*2 + (allWidth - widthOfBanner) ; Левый верхний угол начала вывода
	mov cx, 7                         ; Кол-во строк баннера
loopPrintBanner:                      ;
	push cx                           ; Сохраняем значение cx
                                      ;
	mov cx, widthOfBanner             ; Загружаем в cx ширину выводимого баннера, т.е. длину строки баннера
	rep movsw                         ; rep - повторить cx раз, movsw - записать в ячейку es:di данные из ds:si
                                      ;
	add di, 2*(allWidth - widthOfBanner); Смещаемся на новую строку
                                      ;
	pop cx                            ; Восстанавливаем значение cx
	loop loopPrintBanner              ;
                                      ;
	pop es                            ;
	ret                               ;
ENDP                                  ;
                                      ;
programLength:                        ; Парсинг командной строки
                                      ; Результат: ax = 0 если все ОК, иначе !=0
parseCMD PROC                         ;
	push bx                           ;   
	push cx                           ;
	push dx                           ; Сохраняем значения регистров
	push si                           ;
	push di                           ;
                                      ;
	cld                               ;
	mov bx, 80h                       ;
	mov cl, cs:[bx]                   ; Переходим в смещение, где расположен текст командной строки
	xor ch, ch                        ; В cl загружаем длину командной строки
                                      ;
	xor dx, dx                        ;
	mov di, 81h                       ;
                                      ;
	mov al, ' '                       ; Пропускаем все до пробелов
	repne scasb	                      ; Найти байт, равный al в блоке из cx байт по адресу es:di
	xor ax, ax                        ;
                                      ;
	mov si, di                        ; Загружаем в si смещение, с которого начинаются аргументы
	mov di, offset startHour          ; Начинаем парсинг с startHour
                                      ;
parseCMDloop:                         ;
	mov dl, [si]                      ; Загружаем в dl очередной символ из командной строки
	inc si                            ; Переходим к след элементу
	cmp dl, ' '                       ; Если символ = пробел, переходим в SpaceIsFound
	je SpaceIsFound                   ;
                                      ;
	cmp dl, '0'                       ;
	jl badCMDArgs                     ; Если символ не цифра - ошибка
	cmp dl, '9'                       ;
	jg badCMDArgs                     ;
                                      ;
	sub dl, '0'                       ; Получаем в dl цифру из символа
	mov bl, 10                        ;
	mul bl                            ; Умножаем ax на 10
	add ax, dx                        ; Добавляем в ax dx 
                                      ;
	cmp ax, 60                        ; Сравниваем ax с 60 - если больше, то неверные данные
	jae badCMDArgs				      ; ja - jump after
	cmp ax, 24                        ; Если больше 24, проверяем значение часов
	jae testIsHour                    ;
                                      ;
	loop parseCMDloop                 ;
                                      ;
SpaceIsFound:                         ;
	mov byte ptr es:[di], al          ; Заносим переведенное число в необходимое значение
	cmp di, offset durationSeconds    ; Если последний введенный элемент - продолжительность в секундах - ввод корректный
	je argsIsGood                     ;
                                      ;
	inc di                            ; Иначе увеличиваем di на 1 и продолжаем парсинг уже для следующего значения
	xor ax, ax                        ; Сбрасываем аккумулятор в 0
                                      ;
	loop parseCMDloop                 ; Если парсинг прошел без ошибок - переходим в argIsGood
	jmp argsIsGood                    ;
                                      ;
testIsHour:                           ;
	cmp si, offset startHour          ; 
	je badCMDArgs                     ; Проверяем, если текущее вводимое значение - час начала или продолжительность в часах - ввод некорректен
	cmp si, offset durationHour       ;
	je badCMDArgs                     ;
	                                  ;
	loop parseCMDloop                 ; Если ошибок не произошло - продолжаем парсить строку
	jmp SpaceIsFound                  ;
                                      ;
badCMDArgs:                           ;
	mov dx, offset badCMDArgsMessage  ; Выводим сообщение об ошибке
	call println                      ; Вызываем процедуру вывода
	mov ax, 1                         ; Загружаем в ax 1, т.е произла ошибка
                                      ;
	jmp endproc                       ; Переходим к завершению процедуры
                                      ;
argsIsGood:                           ;
	mov ax, 0                         ; Загружаем в ax = 0, т.е ошибок не произошло
                                      ;
endproc:                              ;
	pop di                            ;
	pop si                            ;
	pop dx                            ; Восстанавливаем значения регистров и выходим из процедуры
	pop cx                            ;
	pop bx                            ;
	                                  ;
	ret	                              ;
ENDP                                  ;
                                      ;                        
                                      ; 
setHandler PROC                       ; Установка нового обработчика прерываний. Результат ax=0 если нет ошибок, иначе ax!=0 
	push bx                           ;
	push dx                           ; Сохраняем значения регистров
                                      ;
	cli                               ; Запрещаем прерывания (запрет/разрешение необходимо для корректной установки нового обработчика )
                                      ;
	mov ah, 35h                       ; Функция получения адреса обработчика прерывания
	mov al, 1Ch                       ; прерывание, обработчик которого необходимо получить (1C - прерывание таймера)
	int 21h                           ; Вызываем прерывание для выполения функции 
                                      ; В результате выполнения функции в es:bx помещается адрес текущего обработчика прерывания                                                 
                                      ;
	                                  ; Сохраняем старый обработчик
	mov word ptr [offset intOldHandler], bx     ;
	mov word ptr [offset intOldHandler + 2], es ;
                                      ;
	push ds			                  ; Сохраняем значение ds
	pop es                            ; Восстанавливаем значение es
                                      ;
	mov ah, 25h                       ; Функция замены обработчика прерывания
	mov al, 1Ch                       ; прерывание, обработчк которого будет заменен
	mov dx, offset handler            ; загружаем в dx смещение нового обработчика прерывания, который будет установлен на место старого обработчика 
	int 21h                           ; Вызываем прерывание для выполнения функции
                                      ;
	sti                               ; Разрешаем прерывания
                                      ;
	mov ax, 0                         ; Загружаем в ax - 0, т.е. ошибок не произошло
                                      ;
	pop dx                            ; Восстанавливаем значения регистров и переходим выходим из процедуры
	pop bx                            ;
	ret                               ;
ENDP                                  ;
                                      ;
newline PROC                          ;
	push ax                           ; Сохраняем значения регистров
	push dx                           ;
                                      ;
	mov dl, 10                        ;	Загружаем в dx последовательно коды возврата каретки 0Ah(10) и 0Dh(13) для перехода на новую строку
	mov ah, 02h                       ; Загружаем в ax код 02h - код операции вывода символа
	int 21h                           ; Вызываем прерывание для вывода символа
                                      ;
	mov dl, 13                        ;
	mov ah, 02h                       ; ==//==
	int 21h                           ;
                                      ;
	pop dx                            ; Восстанавливаем значния регистров
	pop ax                            ;
	ret                               ;
ENDP                                  ;
                                      ;
println PROC                          ;
	push ax                           ; Сохраняем значения регистров
	push dx                           ;
                                      ;
	mov ah, 09h                       ; Загружаеи в ah код вывода строки (в di уже находится выводимая информация)
	int 21h                           ; Вызываем прерывание для выполнения вывода
                                      ;
	call newline                      ; Вызываем newline, т.е. переходим на новую строку
                                      ;
	pop dx                            ; Восстанавливаем значения регистров и выходим из процедуры
	pop ax                            ;
	ret                               ;
ENDP                                  ;
                                      ; Процедура вычисления времени, в которое необходимо выключить будильник
calcucateStopTime PROC                ;
	xor ah, ah                        ; Секунды
	mov al, startSeconds              ; Загружаем время начала
	add al, durationSeconds           ; Добавляем продолжительность 
	mov bl, 60			              ; Делим на 60
	div bl                            ; частное - al, остаток - ah
	mov stopSeconds, ah               ; Записываем во "время остановки в секундах" остаток от деления на 60
                                      ; 
                                      ; После деления на 60 в al может находится 1, т.е. возникший перенос 
                                      ;
	xor ah, ah                        ; Минуты
	add al, startMinutes              ; Загружаем время начала в минутах
	add al, durationMinutes           ; 
	mov bl, 60			              ;   ==//==
	div bl                            ; 
	mov stopMinutes, ah               ;
	                                  ; Часы
	xor ah, ah                        ;
	add al, startHour                 ;
	add al, durationHour              ;   ==//==
	mov bl, 24			              ;
	div bl                            ;
	mov stopHour, ah                  ;
                                      ;
	ret                               ;
ENDP                                  ;
                                      ;
convertToBCD PROC                     ;
	mov cx, 9                         ; Загружаеи в cx 9, чтобы перевести все числа
	                                  ; т.е. 9 = 3*3 = (Часы + Минуты + Секунды) * (Время начала + продолжительность + Время остановки)
	mov bl, 10                        ; =//= в bx 10
	mov si, offset startHour          ; Устанавливаем si на startHour, т.е время начала будильника в часах
convertLoop:                          ; 
	xor ah, ah                        ; Обнуляем ah
	mov al, [si]                      ; Загружаем очередной символ
	div bl                            ; Делим на 10. Частное - al, остаток - ah
                                      ;
	mov dl, al                        ; Загружаеи в dl al, т.е.  частное  от деления на 10
	                                  ; 
	shl dl, 4                         ; Сдвиг влево на 4 (необходимо для BCD формата)
	                                  ; Пример: 12 = 0001 0010
	                                  ;
	add dl, ah                        ; Добавляем в dl ah, т.е  остаток от деления на 10
	mov [si], dl                      ; Переписываем элемент в si на новый в формате bcd
                                      ;
	inc si                            ; Переходим к следующему элементу
	loop convertLoop                  ;
	                                  ;
	ret                               ;
ENDP                                  ;
                                      ;
main:                                 ;
	call parseCMD                     ; Парсим командную строку
	cmp ax, 0                         ; Если возникла ошибка - выходим
	jne endMain                       ; 
                                      ;
	call calcucateStopTime            ; Вычисляем время остановки оповещения
                                      ;
	call convertToBCD                 ; Переводим значения времени начала/ продолжительности/ остановки сингала в BCD код
	                                  ; для последующего корректног взаимодействия с системной функцией получения времени
                                      ;
	call setHandler                   ; Устанавливаем новый обработчик прерывания
	cmp ax, 0                         ; Если возникла ошибка - выходим
	jne endMain				          ; 
                                      ;
	mov ah, 31h                       ; Оставляем программу резидентной
	mov al, 0                         ;    
	                                  ;
	mov dx, (programLength - start + 100h) / 16 + 1 ; Заносим в dx размер программы + PSP,
	                                  ; делим на  16, т.к. в dx необходимо занести размер в 16 байтных параграфах
	int 21h                           ; 
                                      ;
endMain:                              ;
	ret                               ;                               ;
end start                             ;
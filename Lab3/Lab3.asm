.model	small
.stack	100h
.data
            
MaxArrayLength              equ 30            
            
ArrayLength                 db  ?
InputArrayLengthMsgStr      db  0Dh,'Input array length: $'
InputLowerBoundMsgStr       db  0Dh,'Input lower bound: $'  
InputHigherBoundMsgStr      db  0Dh,'Input higher bound: $'  
                                
ErrorInputMsgStr            db  0Dh,'Incorrect value!',0Ah, '$' 
ErrorInputHigherBoundMsgStr db  0Dh,'Higher bound should be geater than lower bound!', 0Ah, '$' 
ErrorInputArrayLengthMsgStr db  0Dh,'Array length should be geater than 0 and not grater than 30!', 0Ah, '$'
                                
InputMsgStr                 db  0Dh,'Input '    
CurrentEl                   db  2 dup(0)
InputMsgStrEnding           db  ' element (-127..127) : $'

Answer                      db  2 dup(0)
ResultMsgStr                db  0Dh, 'Result: $'
                                
Buffer                      db  ?
                                                              
MaxNumLen                   db  5  
Len                         db  ?                          ;Contains length of entered string
buff                        db  5 dup (0)              
                                
minus                       db  0  

Array                       db  MaxArrayLength dup (0) 
                                
LowerBound                  db  ?
HigherBound                 db  ?
                              
.code      
start:                            ;
mov	ax,@data                      ;
mov	ds,ax                         ;
                                  ;
xor	ax,ax                         ;
                                  ;
call input                        ;
call Do                           ;
call output                       ;
                                  ;
                                  ;
input proc                        ;
    call inputLowerBound          ;
    call inputHigherBound         ;
    call inputArrayLength         ;
    call inputArray               ;
                                  ;
    ret                           ;
endp     


inputLowerBound proc
    mov cx, 1                         
    inputLowerBoundLoop:
       call ShowInputLowerBoundMsg                    
       call inputElementBuff          
       
       test ah, ah
       jnz inputLowerBoundLoop 
       
       mov bl, Buffer 
       mov LowerBound, bl
    loop inputLowerBoundLoop                
    ret      
endp    

inputHigherBound proc                                    
    mov cx, 1                         
    inputHigherBoundLoop:
       call ShowInputHigherBoundMsg                    ;
       call inputElementBuff         
              
       test ah, ah
       jnz inputHigherBoundLoop 
       
       mov ah, LowerBound
       cmp Buffer,ah                                          
       jnl inputHigherBoundLoop_OK
       
       call ShowErrorInputHigherBoundMsgStr 
       jmp inputHigherBoundLoop
       
       inputHigherBoundLoop_OK:
       
       mov bl, Buffer 
       mov HigherBound, bl
    loop inputHigherBoundLoop
    ret      
endp     

inputArrayLength proc   
    mov cx, 1           
    inputArrayLengthLoop:
       call ShowInputArrayLengthMsg                    ;
       call inputElementBuff          
       
       test ah, ah
       jnz inputArrayLengthLoop 
       
       cmp Buffer, MaxArrayLength
       jg inputArrayLengthLoop_FAIL   
       
       cmp Buffer, 0
       jg inputArrayLengthLoop_OK   
       ;jmp inputArrayLengthLoop_FAIL
       
       inputArrayLengthLoop_FAIL:
       
       call ShowErrorInputArrayLengthMsgStr 
       jmp inputArrayLengthLoop
       
       inputArrayLengthLoop_OK:
       
       mov bl, Buffer 
       mov ArrayLength, bl                 
    loop inputArrayLengthLoop     
    ret      
endp 

inputArray proc
    xor di,di                     
                                               
    mov cl,ArrayLength            
    inputArrayLoop:
       call ShowInputMsg                    ;
       call inputElementBuff      
       
       test ah, ah
       jnz inputArrayLoop
       
       mov bl, Buffer 
       mov Array[di], bl
       inc di                     
    loop inputArrayLoop           
    ret      
endp  


resetBuffer proc
    mov Buffer, 0    
    ret
endp    

inputElementBuff proc                 ;
    push cx                       ;save cx
    inputElMain:                  ;
        call resetBuffer          ;
        
        mov ah,0Ah                ;Input command  
        lea dx, MaxNumLen         ;
        int 21h                   ;Input
                                  ;
        mov dl,10                 ;Символ который надо вывести на экран
        mov ah,2                  ;Функция DOS вывода символа
        int 21h                   ;Прерывание для выполнения ф-ции
                                  ;
        cmp Len,0                 ;
        je errInputEl             ;If input is exmpty - exit
                                  ;
        mov minus,0               ;Reset minus
        xor bx,bx                 ;Reset bx
                                  ;
        mov bl,Len                ;
        lea si,Len                ;
                                  ;
        add si,bx                 ;
        mov bl,1                  ;
                                  ;
                                  ;
        xor cx,cx                 ;
        mov cl,Len                ;
        inputElLoop:              ;
            std                   ;Установка флага направления движения по массиву
            lodsb                 ;Считать байт по адресу DS:SI в AL
                                  ;Теперь в al находится текущий символ
            call checkSym         ;Проверка число ли это
                                  ;
            cmp ah,1              ;Если ah содержит 1, то значит символ не прошел контроль checkSym и в процессе ее выполнения стал 1
            je errInputEl         ;Обрабатываем данную ситуацию
                                  ;
            cmp ah,2              ;Если ah после выполнения checkSym содержит 2, то значит был введен знак минуса, необходима дальшейная проверка 
            je nextSym            ;
                                  ;
            sub al,'0'            ;Если мы находимся на этом шагу, то в al лежит символ в диапазоне '0'..'9', отнимаем '0' чтобы получить его числовое значение
            mul bl                ;Умножоем текущую цифру на разряд
                                  ;
            test ah,ah            ;Побитовое and с изменением ТОЛЬКО флагов, результат не сохраняется
                                  ;Проверка значения регистра на равенство нулю, Если равно нулю -> Ошибок не выявлено
            jnz errInputEl        ;Если не ноль - ошибка ввода
                                  ;
            add Buffer,al      ;Записываем текущую часть числа в массив. Тип 123 = 3 + 2*10 + 1*100
                                  ;
            jo errInputEl         ;Если есть перепонение
            js errInputEl         ;Знак равен 1
                                  ;
            mov al,bl             ;В al загружаем bl
            mov bl,10             ;В bl 10
            mul bl                ;Умножаем al на 10, переход на следующий разряд числа
                                  ;
            test ah,ah            ;Побитовое and с флагами опять
            jz ElNextCheck        ;Если нуль или равно
                                  ; 
                                  ;
            cmp ah,3              ;Если ah !=3 ошибка ввода
            jne errInputEl        ;Т.к. 0..2 мы проверили, 10^3 в 16сс = 3xx, то 10^3 еще допустима, а из 10^4+ нет
                                  ;
                                  ;
            ElNextCheck:          ;
                mov bl,al         ;
                jmp nextSym       ;
                                  ;
                                  ;
            errInputEl:           ;
                call ShowErrorInputMsg   ;Вывод сообщения об ошибке ввода
                jmp exitInputEl          ;Попытка ввести число заново
                                  ;
            nextSym: 
            xor ah, ah            ;
        loop inputElLoop          ;
                                  ;
    cmp minus,0                   ;
    je exitInputEl                ;
    neg Buffer                    ;
                                  ;
    exitInputEl:                  ;
    pop cx                        ;Восстанавливаем cx
    ret                           ;
endp 
        ;
                                  ;
checkSym proc                     ;
    cmp al,'-'                    ;Если элемент равен минусу, то делаем вывод, что мы пытаемся ввести отрицательное число
    je minusSym                   ;
                                  ;
    cmp al,'9'                    ;
    ja errCheckSym                ;Если символ больше 9 - ошибка ввода
                                  ;
    cmp al,'0'                    ;
    jb errCheckSym                ;Если символ меньше 0 - ошибка ввода
                                  ;
    jmp exitCheckGood             ;Если символ - цифра - переходим в exitCheckGood, где сбрасываем метку ошибки
                                  ;
    minusSym:                     ;
        cmp si,offset Len         ;
        je exitWithMinus          ;
                                  ;
    errCheckSym:                  ;
        mov ah,1                  ;Incorrect symbol
        jmp exitCheckSym          ;
                                  ;
    exitWithMinus:                ;
        mov ah,2                  ;
        mov minus, 1              ;Устанавливаем метку, что число отрицательное
        cmp Len, 1                ;
        je errCheckSym            ;Если число состоит только из минуса либо были введены 2+ минуса - ошибка ввода!
                                  ;
        jmp exitCheckSym          ;
                                  ;
    exitCheckGood:                ;
        xor ah,ah                 ;Ah = 0 
                                  ;
    exitCheckSym:                 ;
        ret                       ;
endp                              ;
                                  ;
ShowErrorInputMsg proc                   ;Вывод сообщения об ошибке вывода
    lea dx, ErrorInputMsgStr      ;
    mov ah, 09h                   ;
    int 21h                       ;
    ret                           ;
endp                              ;
      

ShowInputArrayLengthMsg proc
    push ax
    push dx
      
    mov ah,09h                      
    lea dx, InputArrayLengthMsgStr           
    int 21h  
    
    pop ax
    pop dx 
     
    ret
endp       
         
ShowInputLowerBoundMsg proc
    push ax
    push dx
      
    mov ah,09h                      
    lea dx, InputLowerBoundMsgStr           
    int 21h  
    
    pop ax
    pop dx 
     
    ret
endp    

ShowInputHigherBoundMsg proc
    push ax
    push dx
      
    mov ah,09h                      
    lea dx, InputHigherBoundMsgStr           
    int 21h  
    
    pop ax
    pop dx 
     
    ret
endp  
                                  ;
ShowInputMsg proc                     ;
    mov ax,di                     ;di contains num
              
    mov ax, di         
    mov bl, 10
    div bl          
              
    push di
        
    xor di, di    
    inc di
    mov CurrentEl[di], ah
    add CurrentEl[di], '0'
    
    test al, al 
    jz lessThanTen
    
    dec di
    mov CurrentEl[di], al                      
    add CurrentEl[di], '0'           
           
    lessThanTen:                      ;
                                  ;
    mov ah,09h                    ;output command
    lea dx, InputMsgStr           ;show input msg to user
    int 21h   
    
    pop di
                        ;
    ret                           ;
endp    

ShowErrorInputHigherBoundMsgStr proc
    push ax
    push dx
      
    mov ah,09h                      
    lea dx, ErrorInputHigherBoundMsgStr           
    int 21h  
    
    pop ax
    pop dx 
     
    ret
endp       

ShowErrorInputArrayLengthMsgStr proc
    push ax
    push dx
      
    mov ah,09h                      
    lea dx, ErrorInputArrayLengthMsgStr           
    int 21h  
    
    pop ax
    pop dx 
     
    ret
endp

                                  ;
CheckMatch proc                   ;Процедура сравнения
    mov ah, LowerBound                   ;Загружаем в ah левую границу диапазона
    cmp Array[di],ah              ;Сравниваем                                         
    jl notMatch                   ;Если можно сделать вывод, что элемент диапазону не принадлежит - выходим из процедуры
                                  ;
    mov ah, HigherBound           ;Аналогично для правой границы массива
    cmp Array[di],ah              ;
    jg notMatch                   ;
                                  ;
    inc bx                        ;bx содержит сколько элементов                   ;
                                  ;
    notMatch:                     ;
    ret                           ;
endp                              ;
                                  ;
Do proc                           ;
    xor bx, bx                    ;Обнуляем bx, т.к в bx будет храниться ответ
    mov cl,ArrayLength            ;Загружаем в cx длину массива, чтобы через loop пройтись по каждому элементу
    xor di, di                    ;Обнуляем di, т.к. проход будем начинать в нулевого элемента
    DoLoop:                       ;
        call CheckMatch           ;Вызов функции проверки
        inc  di                   ;Увеличиваем di чтобы перейти к новому элементу
    loop DoLoop                   ;
    ret                           ;
endp                              ;
                                  ;
output proc                       ;
    lea dx, ResultMsgStr          ;                                                        
    mov ah, 09h
    int 21h
            
    mov ax, bx         
    mov al, bl
    mov bl, 10
    div bl
                   
    xor di, di    
    inc di
    mov Answer[di], ah
    add Answer[di], '0'
    
    test al, al 
    jz lessThanTen1
    
    dec di
    mov Answer[di], al                      
    add Answer[di], '0'           
           
    lessThanTen1:                      ;
    
    lea dx, Answer
    mov ah, 09h 
    int 21h  
        
    xor ax, ax                              ;
    mov	ah,4ch                    ;Выходим из программы
    int	21h                       ;
    ret                           ;
endp                              ;
                                  ;
end	start                         ;
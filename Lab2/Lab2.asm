.model small                   ;
.stack 100h                    ;
 
.data
msgEnterString       db "Enter string: $"
msgEnterSubstring    db 0Ah, 0Dh, "Enter substring: $"
msgResult            db 0Ah, 0Dh, "Result string: $" 
msgError             db 0Ah, 0Dh, "Incorrect input! Substring is empty or contains 1+ words or spaces!$" 
enterStr             db 0Ah, 0Dh, '$'
max_length           equ 200   ; length = 200
 
Strb db '$'                    ;
Strl db max_length                                  ; contains str length after input
String  db max_length dup('$')                         ; '$$$..' 200 times
                               ;
SubStrb db '$'                 ;
SubStrl db max_length          ;     =/=
SubString  db max_length dup('$')     ;
                               ;                                                            
.code                          ;
start:                         ;
                               ;@data - DATASEG identeficator
    mov ax, @data              ;Link data segment adress with his real place in memory
    mov ds, ax                 ;because when program initializes code segment and data segment had the same adress
                               ;Move adress of data beginin to ds trought ax, because mov ds, @data not exists
                 
    call enterString           ;Input string
    call enterSubstring        ;Input substring
         
  
    call exitIfEmpty           ;Exit if string & strings are equals  
    call exitIfNotSingleWord   ;Exit if substring contains 1+ words or spaces before word
      
    xor cx, cx                 ;Reset couter
    lea si, String             ;Seting pointer on beginning of Str; mov si, offset Str
    dec si                     ;
    jmp skip_spaces            ;Jump to skip_spaces loop

    
    find:                      ;This loop sets si at the begining of next word
        inc si                 ;
        push bx 
        mov bl, [si]               ;
        cmp bl, ' '          ;Compare element of Str with ' '
        pop bx
        je skip_spaces         ;If current string elem is ' ' - start new search 
        
        push bx 
        mov bl, [si]
        cmp bl, '$'          ;Compare with end of Str    
        pop bx
        je exit                ;If end of string reached - exit 
        
        jmp find               ;If current elem is a character - skip (cause we need to delete whole word, not it's substring)
        
        skip_spaces:           ;This loop skips all spaces before next word
            inc si   
            push bx 
            mov bl, [si]
            cmp bl, ' '
            pop bx
           je skip_spaces      
           
        lea di, SubString      ;Set pointer on beginning of SubString
        call searchSubString   ;Serching substring procedure
       jmp find                ;Endless loop
          
    error_exit:
        call outputErrorResult ;      
          
    exit:  
        call outputResult      ;Output result   
                 
inputString proc               ;Input value procedure
    push ax                    ;Save ax register   
    mov ah, 0Ah                ;Move to ah register "String input" command
    int 21h                    ;System interrupt 
    pop ax                     ;Restore ax register
    ret                        ;Return control
inputString endp               ;End of procedure
 
outputString proc              ;Output value procedure
    push ax                    ;Save ax register
    mov ah, 09h                ;Move to ah register "String ouput" command
    int 21h                    ;System interrupt
    pop ax                     ;Restore ax register
    ret                        ;Return control
outputString endp              ;End of procedure
 
enterString proc               ;
    lea dx, msgEnterString     ;Move to dx 'Enter string'
    call outputString          ;Output message
    lea dx, Strb               ;Input MainString 
    mov Strb[0], max_length
    call inputString           ;Input string
    ret                        ;Return control
enterString endp               ;
                            
enterSubstring proc            ;
    lea dx, msgEnterSubstring  ;Output  'Enter substring'
    call outputString          ;
    lea dx, SubStrb            ;Input SubString 
    mov SubStrb[0], max_length
    call inputString           ;
    ret                        ;
enterSubstring endp            ;

outputResult proc              ;
    lea dx, msgResult          ;Output Result message
    call outputString          ;
    lea dx, String             ;equals to mov dx, offset Str
    call outputString          ;
           
    lea dx, enterStr
    call outputString       
           
    xor ax, ax    
    mov ah,4ch               ;
    int 21h  
    ret                  ;
outputResult endp   

outputErrorResult proc              ;
    lea dx, msgError           ;Output Result message
    call outputString          ;          ;
    mov ax, 4ch                ;
    int 21h  
    ret                  ;
outputErrorResult endp         ;
                           

exitIfEmpty proc   
    push cx
    push di
                   ;
    lea di, SubString  
    dec di
    
    skip_spaces_sub:           ;This loop skips all spaces before next word
            inc di             ;
            push bx 
            mov bl, [di]
            cmp bl,' '       ; 
            pop bx
           je skip_spaces_sub  ;
          
    push bx 
    mov bl, [di]                           ;
    cmp bl, 0Dh              ;Compare value in al reg with substring's length        
    pop bx
    error_exit_marker:
    je error_exit              ;If SubStr is empty or consists only of spaces - exit 
       
    pop cx
    pop di
    ret                        
exitIfEmpty endp      

exitIfNotSingleWord proc   
    push cx
    push di
                   ;
    lea di, SubString  
    dec di
            
    mov cl, [SubStrl]
    check_substr:             ;This loop skips all spaces before next word
            inc di            ;
            push bx 
            mov bl, [di]
            cmp bl,' '        ;
            pop bx      
           je error_exit_marker ;
    loop check_substr         ;
                              ;
    pop cx                    ;
    pop di                    ;
    ret                       ; 
exitIfNotSingleWord endp      ;
                                              
       
    
searchSubString proc             ;
    push ax                      ;
    push cx                      ;
    push di                      ;
    push si                      ;Save ax, cx, di, si values
                                 ;
    xor cx, cx                   ;Reset cx
    mov cl, [SubStrl]            ;Move to cx length of substring
    comparestr:                  ;
        mov ah,[si]              ;Move to ah [si] symbol of string
        dec cx                   ;Decrease cx
        cmp ah,[di]              ;Compare corresponding symbols of string and substring
        je  compare              ;If compare result == true : move to compare
        jne NotEqual             ;        =/=       == false: process NotEqual result
        compare:                 ;
            inc si               ;Move to next symbol of string
            inc di               ;        =/=         of substring
            cmp cx,0             ;Compare cx with zero
            je check             ;If cx = 0 -> end of substring reached -> move to check 
          jne comparestr         ;      > 0 -> repeat to compare next pair of symbols 
                                 ;
        check:      
            push bx 
            mov bl, [si]                 ;
            cmp bl, ' '          ;
            pop bx
            je Equal             ;
            jne NotEqual         ;
                                 ;
        Equal:                   ;
            call lengthProc          ;Get length word
            call shift           ;Shift left the rest of string  
            call searchSubString ;Repeat
                                 ;
        NotEqual:                ;
            pop si               ;
            pop di               ;
            pop cx               ;
            pop ax               ;
            ret                  ;Restore values of ax, cx, di, si registers                                ;
searchSubString endp             ;
                                 ;
                                 ;
shift proc                       ;
    push cx                      ;
    push di                      ;
    push bx                      ;Save 
                                 ;
    lea ax, String                  ;Move Str to ax
    add al, [Strl]               ;Add Str length to al 
    sub ax,si                    ;Subtract si from ax
    mov cx,ax                    ;Move ax to cx; Now cx containt length of rest of string
    add cx,2                     ;KocTbll'
                                 ;
    ;shifting the word           ;
    shift_left:                  ;
        mov ah,[si]              ;save current element
        sub si, bx               ;shift left
        mov [si], ah             ;shift element on bx position left 
        add si, bx               ;restore si value
        inc si                   ;move to next symbol
    loop shift_left              ;
                                 ;reset bh
                                 ;
    pop bx                       ;
    pop di                       ;
    pop cx                       ;Restore values
    ret                          ;
shift endp                       ;
                                 ;
lengthProc proc                      ;
    push ax                      ;
    skip:                        ;
    inc si  
    push bx 
    mov bl, [si]                     ;
    cmp bl, ' '
    pop bx                ;
    je skip                      ;
    mov ax,si                    ;compare element of Str with ' '  
                                 ;
    wordMarker:                        ;
    mov dh,[si]                  ;
    inc si    
    push bx 
    mov bl, [si]                   ;
    cmp bl, ' '                  ;compare with end of Str
    pop bx
    je continue                  ;
    push bx 
    mov bl, [si]
    cmp bl, '$'                  ;
    pop bx
    je continue                  ;
    jmp wordMarker                     ;
    continue:                    ;
    push si                      ;
    sub si,ax                    ;
    mov bx,si                    ;
                                 ;
    pop si                       ;
    pop ax                       ;
    ret                          ;
lengthProc endp                      ;
                                 ;
end start                        ;
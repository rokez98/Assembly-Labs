.model tiny
.code 
org 100h 
mov cx, 2          
procHelloWorld:  
       mov ah, 9
       mov dx, offset msgHello
       int 21h                   
       mov dx, offset msgWorld  
       int 21h 
       loop procHelloWorld
       ret
msgHello db "Hello, ",'$'
msgWorld db "World!", 0Dh, 0Ah, '$'
       end procHelloWorld    

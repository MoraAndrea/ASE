.MODEL small
.STACK
.DATA

vet DB lung(?)

.CODE 
.startup
mov si,0
mov cx,0
ciclo:  mov al,vet[SI]
        inc si
        loop
    

.exit
end
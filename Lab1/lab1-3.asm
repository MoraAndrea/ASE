.MODEL small
.STACK
.DATA
var1 DW 10
var2 DW 20   
ris DW ?

.CODE 
.startup

mov ax,var1
add ax,var2
mov ris,ax

.exit
end
#start=8259.exe#

    .model small          
    .data     
          
SOMMA dw 0    
SOMMA_GOLD dw 0
FLAG db 0          
NUM db 0
NUM_GOLD db 0
NUM_COLPI db 0          
          
    .stack     
    .code   
    
    
    ; procedura di inizializzazione della interrupt vector table
INIT_IVT	PROC
		PUSH 	AX
		PUSH	BX
		PUSH	DX
		PUSH 	DS
		XOR	AX, 	AX
		MOV	DS, 	AX      
		
	    ; channel 7
		MOV	BX, 	39		
		SHL	BX, 	2		
		MOV AX, 	offset ISR_PA_IN
		MOV	DS:[BX], 	AX
		MOV	AX,     seg ISR_PA_IN
		MOV	DS:[BX+2], 	AX            		
      		
		; channel 3
		MOV	BX, 	35		
		SHL	BX, 	2		
		MOV AX, 	offset ISR_COUNT0
		MOV	DS:[BX], 	AX
		MOV	AX,     seg ISR_COUNT0
		MOV	DS:[BX+2], 	AX 					
			
										
		POP	DS
		POP	DX
		POP	BX
		POP	AX 		
		RET

INIT_IVT	ENDP

; ISR for reading the value received on PA            
ISR_PA_IN   PROC                
            
            in al,080h  
            cbw   
            inc num_colpi  
            cmp al, 0
            jne fine
            
            mov flag,3
            mov ax, somma
            mov somma_gold,ax
            mov al,num                  
            mov num_gold,al

fine:                
            IRET    
ISR_PA_IN   ENDP             
                                              

; ISR executed when count0 ends                
ISR_COUNT0  PROC        
            
            cmp num_colpi, 10
            jb fine_cnt  
               
            cmp flag,0        ;flag che controlla se sta inviando
            je fine_cnt
            
            cmp flag,3
            jne f2
            dec num_gold
            mov al,num_gold
            out 81h,al
            dec flag
            jmp fine_cnt
f2:         cmp flag,2
            jne f3
            mov al, byte ptr somma_gold
            out 81h,al
            dec flag
            jmp fine_cnt
f3:         cmp flag,1
            jne fine_cnt
            mov al,byte ptr somma_gold+1
            out 81h,al
            dec flag    
            mov num_colpi,0
            jmp fine_cnt
    
fine_cnt:               
            
            IRET    
ISR_COUNT0  ENDP   

                 
INIT_8255   PROC
            ; init 8255    
            mov al, 10110000b;
            out 083h, al
            ; set PC4 to enable interrupt on PA in
            mov al, 00001001b    
            out 083h, al   
            ; set PC2 to enable interrupt on PB in or PB out
            mov al, 00000101b 
            out 083h, al   
            ; set PC6 to enable interrupt on PA out
            ;mov al, 00001101b 
            ;out 083h, al  
            RET            
INIT_8255   ENDP          

INIT_8253   PROC
            ;init 8253
             ;counter0 init
            mov al, 00110100b
            out 063h, al 
             ;counter1 init
            ;mov al, 01010100b
            ;out 063h, al  
             ;counter2 init    
            ;mov al, 10010000b
            ;out 063h, al 
             ;counter0 value                       
            mov ax,  37500        ;devo fare 375000 solo con count0
            out 060h, al             ;10 volte 37500
            xchg ah,al
            out 060h, al
                                       
             ;counter1 value
            ;mov al, 00000100b
            ;out 061h, al          
             ;counter2 value 
            ;mov al, 00000010b
            ;out 062h, al
            RET
INIT_8253   ENDP    

; init 8259      
INIT_8259   PROC
            PUSH DX
       	    PUSH AX
            MOV	DX, 40H
            MOV	AL, 00010011b  ; ICW1
            ; edge triggered
            ; single 8259
            ; IC4 = si
	        OUT	DX, AL
	        MOV	DX, 41H
	        MOV	AL, 00100000b  ; ICW2
	        ; a partire da INTR 32
	        OUT	DX, AL
	        MOV AL, 00000011b  ; ICW4
	        ; fully nested mode
	        ; buf mode
	        ; master
	        ; Automatic End Of Interrupt
	        ;MOV AL, 00000001b  ; ICW4
	        ; fully nested mode
	        ; buf mode
	        ; master
	        ; normal End Of Interrupt
	        OUT DX, AL
	        MOV AL, 00000000b  ; OCW1   
	        ;no channel enabled
	        MOV DX, 41H
	        OUT DX, AL
	        POP DX
	        POP AX
	        RET
INIT_8259   ENDP


;programma principale
            .startup    
            CLI         
            call INIT_IVT
	        call INIT_8259 
            call INIT_8253 
            call INIT_8255
            STI        
                                              
block:      ;hlt
            jmp  block
                      
            .exit

            end  ; set entry point and stop the assembler.


;Considerata una frequenza di pilotaggio di 10KHz, di scriva un programma per il sistema in modo che
    ;a. scateni una interruzione dopo aver atteso di 1 millisecondo, a seguito della quale un
        ;valore viene letto dalla porta A dell’8255
    ;b. scateni una interruzione ogni 1 minuto, a seguito della quale invia alla porta B il
        ;numero di valori ricevuti durante l’ultimo intervallo (1 minuto)
    ;c. scateni una interruzione a seguito dell’attesa di 1 ora, a seguito del quale invia alla
        ;porta C valore medio dei dati ricevuti durante l’ultimo intervallo (1 ora)
    
    ;10KHz 10000*0.001=10 colpi per interrupt ogni millisecondi
    ;      10000*60=600000 colpi per interrupt ogni minuto
              ;uso counter 1=1000 e 2=600 -->ogni 1000 scatti di c2 è passato un minuto
    ;      per ogni ora si contano 60 interrupt da 1 minuto 
    
    #start=8259.exe#
    .model small          
    .data     
     
     COUNTER DW 0
     SOMMA DW 0
     INTER DW 0
     
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
		; channel 4
		MOV	BX, 	36		
		SHL	BX, 	2		
		MOV AX, 	offset ISR_PB_OUT
		MOV	DS:[BX], 	AX
		MOV	AX,     seg ISR_PB_OUT
		MOV	DS:[BX+2], 	AX       		
		; channel 3
		MOV	BX, 	35		
		SHL	BX, 	2		
		MOV AX, 	offset ISR_COUNT0
		MOV	DS:[BX], 	AX
		MOV	AX,     seg ISR_COUNT0
		MOV	DS:[BX+2], 	AX 					
		; channel 2
		MOV	BX, 	34		
		SHL	BX, 	2		
		MOV AX, 	offset ISR_COUNT12
		MOV	DS:[BX], 	AX
		MOV	AX,     seg ISR_COUNT12
		MOV	DS:[BX+2], 	AX 					
										
		POP	DS
		POP	DX
		POP	BX
		POP	AX 		
		RET
INIT_IVT	ENDP

; ISR for reading the value received on PA            
ISR_PA_IN   PROC                
            
            ;devo contare i valori
            inc COUNTER
            in al, 080h 
            mov ah,0
            add SOMMA,ax
                
            IRET    
ISR_PA_IN   ENDP                       
                                          
; ISR for waiting a confirmation that the value written on PB is externally read                                           
ISR_PB_OUT  PROC        
                 
            mov ax,counter
            out 81h,al
                
            IRET    
ISR_PB_OUT  ENDP 

ISR_PC_OUT  PROC               
            ;mando la media dei numero dei valori ricevuti ogni minuto
               
            mov ax , somma
            div counter 
            out 82h , al               
                                   
            IRET    
ISR_PC_OUT  ENDP
                
; ISR executed when count0 ends                
ISR_COUNT0  PROC         
            
            call ISR_PA_IN  
                         
            IRET    
ISR_COUNT0  ENDP   


; ISR executed when count2 ends                                 
ISR_COUNT12 PROC 
            
            ;incremento numero di interrupt ricevuti, se =1000
            ;passato un minuto invio a porta B
            inc inter
            cmp inter,2 
            je pb 
            jmp ISR_PB_OUT
            
   pb:      jmp ISR_PC_OUT        
                
            
            IRET    
ISR_COUNT12 ENDP                  
                 
INIT_8255   PROC
            ; init 8255    
            mov al, 10010000b
            out 083h, al
            ; set PC4 to enable interrupt on PA in
            mov al, 00001001b    
            out 083h, al   
            ; set PC2 to enable interrupt on PB in or PB out
            mov al, 00000101b 
            out 083h, al   
            ; set PC6 to enable interrupt on PA out
            mov al, 00001101b 
            ;out 083h, al  
            ;PC in out
            ;mov al, 10010100b 
            out 083h, al 
            RET            
INIT_8255   ENDP          

INIT_8253   PROC
            ;init 8253
             ;counter0 init
            mov al, 00110100b
            out 063h, al
             
             ;counter1 init
            mov al, 01110100b
            out 063h, al 
         
             ;counter2 init    
            mov al, 10110100b
            out 063h, al
         
             ;counter0 value                       
            mov al, 00001010b
            out 060h, al           ;10
            mov al, 00000000b
            out 060h, al 
                                    
             ;counter1 value
            mov ax, 0ea60h
            out 061h, al         ;60000
            mov al, ah
            out 061h, al  
               
             ;counter2 value 
            mov al, 0ah
            out 062h, al          ;10
            mov al, 00h
            out 062h, al
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
	        ;MOV AL, 11111111b  ; OCW1
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


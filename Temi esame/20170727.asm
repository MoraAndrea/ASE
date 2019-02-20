    #start=8259.exe#
    
    .model small          
    .data     
          
vett db 100 dup (0)
count db 0
flag_s db 0
flag_error db 0    
          
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
		 					
										
		POP	DS
		POP	DX
		POP	BX
		POP	AX 		
		RET
INIT_IVT	ENDP

; ISR for reading the value received on PA            
ISR_PA_IN   PROC                
            
            ;controllo se sto inviando dati
            cmp flag_s,1
            je send_error
            
            ;acquisisco dati fino a quando arriva negativo
            in al,080h 
            cmp al,0
            jb invia
            
            mov di,word ptr count  
            inc count
            mov vett[di],al 
            jmp fine

invia:      mov flag_s,1
            mov al, word ptr count    ;primo invio counter
            out 081h, al   ;avvio output, inizio l'invio su porta B
            jmp fine

send_error: mov flag_error,2          
            
fine:                    
            IRET    
ISR_PA_IN   ENDP                    
                                          
; ISR for waiting a confirmation that the value written on PB is externally read                                           
ISR_PB_OUT  PROC  
           ;mando vettore poi 0, poi linterrupt deve essere riabilitato
            STI
            
            cmp flag_error, 0
            jne error2
            
            cmp count,0
            je fine_vect     ;vettore finito riabilito ricezione da A
            mov di,word ptr count
            mov al, vett[di] 
            mov vett[di],0
            out 081h,al  
            dec count 
            jmp next

fine_vect: ;devo inviare uno 0
            mov al,0
            out 081h,al
            mov flag_s, 0
            jmp next
           
           ;mando per due intervalli              
error2:    dec flag_error  
           mov al,0xFF
           out 081h, al

next:  
            CLI                  
            IRET    
ISR_PB_OUT  ENDP         

                 
INIT_8255   PROC
            ; init 8255    
            mov al, 10110100b;
            out 083h, al
            ; set PC4 to enable interrupt on PA in
            mov al, 00001001b     
            out 083h, al          ;abilito int da porta A str (in)
            ; set PC2 to enable interrupt on PB in or PB out
            mov al, 00000101b 
            out 083h, al    ;IMPORTANTE ;abilito int da porta B ack (out)
            ; set PC6 to enable interrupt on PA out
            ;mov al, 00001101b 
            ;out 083h, al  
            RET            
INIT_8255   ENDP          

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
	        MOV AL, 01101111b  ; OCW1   
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
            call INIT_8255
            STI        
                        
            
block:      ;hlt
            jmp  block
                      
            .exit

            end  ; set entry point and stop the assembler.


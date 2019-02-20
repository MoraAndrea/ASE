                                             #start=8259.exe#
  
    .model small          
    .data     

vett db 256 dup (0) 
max db 0
max_val db 0
flag db 0 
flag_err db 1

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
		; channel 6
		MOV	BX, 	38		
		SHL	BX, 	2		
		MOV AX, 	offset ISR_PA_OUT
		MOV	DS:[BX], 	AX
		MOV	AX,     seg ISR_PA_OUT
		MOV	DS:[BX+2], 	AX       		
		; channel 5
		MOV	BX, 	37		
		SHL	BX, 	2		
		MOV AX, 	offset ISR_PB_IN
		MOV	DS:[BX], 	AX
		MOV	AX,     seg ISR_PB_IN
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
            
            mov flag_err,0
            cmp flag,0
            jne secondo
            in al,080h
            cbw
            mov si, ax
            inc vett[si]   ;per carattere e numero di occorrenze

            jmp fine
            
secondo:    in al,080h  
            cbw
            mov si, ax
            inc vett[si]   ;per carattere e numero di occorrenze in vett2
                                    
fine:           
            IRET    
ISR_PA_IN   ENDP             
              
; ISR for waiting a confirmation that the value written on PA is externally read 
ISR_PA_OUT  PROC               


                                      
            IRET    
ISR_PA_OUT  ENDP                                  
                           
; ISR for reading the value received on PB                                       
ISR_PB_IN   PROC              
            
            
            
                                            
            IRET    
ISR_PB_IN   ENDP             
                                          
; ISR for waiting a confirmation that the value written on PB is externally read                                           
ISR_PB_OUT  PROC  
            
            cmp flag_err,1
            je basta
            mov al,max
            out 081h,al   
basta: mov flag_err,0                          
            IRET    
ISR_PB_OUT  ENDP         
                
; ISR executed when count0 ends                
ISR_COUNT0  PROC         
            cmp flag_err,1
            je control
            
            cmp flag,1
            je vet2
             
            mov cx, 256
            mov di, 0
            mov al, 0
ciclo:      cmp vett[di],al
            ja maximum      ;if (destination > source ) goto maximum
            inc di
            cmp cx, di      ;if (CX != DI) goto ciclo
            jnz ciclo
            jmp next
maximum:    mov al, vett[di]
            mov word ptr max_val,di
            inc di
            cmp cx,di
            jnz ciclo       ;if (CX != DI) goto ciclo   
            
next:       mov max,al
            jmp control: 
                       
vet2:       mov cx, 256
            mov di, 0
            mov al, 0
ciclo1:     cmp vett[di],al
            ja maximum1      ;if (destination > source ) goto maximum
            inc di
            cmp cx, di      ;if (CX != DI) goto ciclo
            jnz ciclo1 
            jmp next1
maximum1:   mov al, vett[di]
            mov word ptr max_val,di
            inc di
            cmp cx,di
            jnz ciclo1       ;if (CX != DI) goto ciclo   
            
next1:      mov max,al                      
            
control:    cmp max,0
            je no_dati
            mov al,max_val
            out 081h,al 
            jmp fine1 

no_dati:    mov flag_err,1
            mov al,0xFF
            out 081h,al                               
                           
fine1:                           
            IRET    
ISR_COUNT0  ENDP   


; ISR executed when count2 ends                                 
ISR_COUNT12 PROC 
                 
            
            IRET    
ISR_COUNT12 ENDP                  
                 
INIT_8255   PROC
            ; init 8255    
            mov al, 10110100b;
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
            mov ax,  450
            out 060h, al
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


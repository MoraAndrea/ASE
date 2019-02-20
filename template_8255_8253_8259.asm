    #start=8259.exe#
    
    .model small          
    .data     

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
		; channel 4
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

                              
            IRET    
ISR_PB_OUT  ENDP         
                
; ISR executed when count0 ends                
ISR_COUNT0  PROC         
               
              
            
            IRET    
ISR_COUNT0  ENDP   


; ISR executed when count2 ends                                 
ISR_COUNT12 PROC 
                 
            
            IRET    
ISR_COUNT12 ENDP                  
                 
INIT_8255   PROC
            ; init 8255    
            mov al, 10110000b;
            out 083h, al
            ; set PC4 to enable interrupt on PA in
            mov al, 00001001b    
            ;out 083h, al   
            ; set PC2 to enable interrupt on PB in or PB out
            ;mov al, 00000101b 
            ;out 083h, al   
            ; set PC6 to enable interrupt on PA out
            ;mov al, 00001101b 
            ;out 083h, al  
            RET            
INIT_8255   ENDP          

INIT_8253   PROC
            ;init 8253
             ;counter0 init
            mov al, 00110110b
            out 063h, al 
             ;counter1 init
            mov al, 01010100b
            out 063h, al  
             ;counter2 init    
            mov al, 10010000b
            out 063h, al 
             ;counter0 value                       
            mov al,  1111100b
            out 060h, al
            mov al,  0000100b
            out 060h, al                             
             ;counter1 value
            mov al, 00000100b
            out 061h, al          
             ;counter2 value 
            mov al, 00000010b
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
	    ;MOV AL, 00000011b  ; ICW4
	        ; fully nested mode
	        ; buf mode
	        ; master
	        ; Automatic End Of Interrupt
	     MOV AL, 00000001b  ; ICW4
	        ; fully nested mode
	        ; buf mode
	        ; master
	        ; normal End Of Interrupt
	     OUT DX, AL
	     MOV AL, 11111111b  ; OCW1   
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


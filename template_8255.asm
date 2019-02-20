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
              
; ISR for writing on PA out mode 1
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
            
    
    .startup    
    CLI         
    call INIT_IVT
    STI            

    mov al, 10010000b ; GA(m=1,pa=in,pcu=hndsk/intrpt) ; GB(m=1,pb=out,pcl=hndsk/intrpt)  
    out 083h, al
    ; set PC4 to enable interrupt on PA in
    ;mov al, 00001001b    
    ;out 083h, al   
    ; set PC2 to enable interrupt on PB in or PB out
    ;mov al, 00000101b 
    ;out 083h, al   
    ; set PC6 to enable interrupt on PA out
    ;mov al, 00001101b 
    ;out 083h, al
    
              
next:  
    
    in al, 080h 
    
    jmp next
          
    ;hlt
    
    .exit

    end  ; set entry point and stop the assembler.

#start=8259.exe#
  
    .model small          
    .data 

seq db 20 dup 0
seq_gold db 20 dup 0  
max db 0
count dw 0
flag_send db 0

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
            
            in al,080h 
            cmp al,0
            je ok_invio
            cmp al,seq[si-2]
            je fine  
            cmp al,max
            jb next 
            mov max,al
next:       cmp al,max/2
            jb fine
            cmp flag_send,1
            je second 
            mov seq[si],al
            jmp here            
second:     mov seq_gold[si],al 
            
here:       inc si
 
            jmp fine
            
ok_invio:   mov seq[si],al
            mov seq_gold[si],al
            mov flag_send,1  
            mov count,si  
            xor si,si                  

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

                              
            IRET    
ISR_PB_OUT  ENDP         
                
; ISR executed when count0 ends                
ISR_COUNT0  PROC         
               
              
            
            IRET    
ISR_COUNT0  ENDP   


; ISR executed when count2 ends                                 
ISR_COUNT12 PROC 
            sti
            cmp flag_send,1
            jne fine1
            
            cmp di, count
            je fine1
            mov al,seq_gold[di]
            out 081h,al
            mov seq_gold[di],0 
            inc di 
            jmp fine1   
azzera:     xor di,di
            mov flag_send,0       
                 
fine1:      
            cli       
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
           ; mov al, 00110110b
           ; out 063h, al 
             ;counter1 init
            mov al, 01010100b
            out 063h, al  
             ;counter2 init    
            mov al, 10010100b
            out 063h, al 
             ;counter0 value                       
           ; mov ax,  10000
           ; out 060h, al
           ; xchg al,  ah
           ; out 060h, al                             
             ;counter1 value
            mov ax, 1000
            out 061h, al
            xchg al,ah
            out 061h, al          
             ;counter2 value 
            mov ax, 2000
            out 062h, al
            xchg al,ah
            out 061h, al
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
            
            xor si,si            
            
block:      ;hlt
            jmp  block
                      
            .exit

            end  ; set entry point and stop the assembler.


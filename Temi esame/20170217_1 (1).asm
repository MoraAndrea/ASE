#start=8259.exe#
  
    .model small          
    .data     

vett_occ db 255 dup (0)  
vett_occ_gold db 255 dup (0)   
maxOcc db 0
maxChar db '0' 
maxOcc_gold db 0
maxChar_gold db '0'
flag_send db 0   
flag_send_last db 0

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
										
		POP	DS
		POP	DX
		POP	BX
		POP	AX 		
		RET
INIT_IVT	ENDP
                                        
; ISR for reading the value received on PA            
ISR_PA_IN   PROC                
                
            in al, 080h
            cbw
            cmp flag_send_last,1     ;sto mandando il vett1
            je gold                  ;se 0(inizio) metti su vett1
            mov si,ax
            inc vett_occ[si]
            mov dl,maxOcc
            cmp vett_occ[si],dl
            jb here
            mov maxChar, al 
            mov dl,vett_occ[si]
            mov maxOcc,dl

here:       jmp fineA     
            
gold:       mov di,ax
            inc vett_occ_gold[di]
            mov dl,maxOcc_gold
            cmp vett_occ_gold[di],dl
            jb here2
            mov maxChar_gold, al     
            mov dl,vett_occ_gold[di]
            mov maxOcc_gold,dl
            
here2:      jmp fineA
            
fineA:                     
            IRET    
ISR_PA_IN   ENDP             
                                          
; ISR for waiting a confirmation that the value written on PB is externally read                                           
ISR_PB_OUT  PROC  
            cmp flag_send,0
            je fineB
            sti 
            cmp flag_send_last,2
            je second1
            mov al,maxOcc  
            out 081h,al  
            mov maxOcc,0
            mov maxChar,0 
            mov flag_send,0
            ;andrebbe azzerato vettore   
            jmp fineB

second1:    mov al,maxOcc_gold
            out 081h,al  
            mov maxOcc_gold,0
            mov maxChar_gold,0 
            mov flag_send,0

fineB:                         
            cli                  
            IRET    
ISR_PB_OUT  ENDP         
                
; ISR executed when count0 ends                
ISR_COUNT0  PROC
            
            cmp flag_send_last,1
            je second       ;se 0 o 1 vai dritto  
            sti 
            mov flag_send_last,1          ;invio vett1    
            mov flag_send,1
            cmp maxOcc,0
            je zero
            mov al,maxChar
            out 081h,al       ;avviamento
            jmp fine   

second:     mov flag_send_last,2      ;invio vett2
            mov flag_send,2
            cmp maxOcc_gold,0
            je zero
            mov al,maxChar_gold
            out 081h,al       ;avviamento
            jmp fine   


zero:       mov al,0xFF
            out 081h,al
            mov flag_send,0
            jmp fine             
             
fine:               
            cli
            IRET    
ISR_COUNT0  ENDP                    
                 
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
            xchg al,  ah
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
	        MOV AL, 01100111b  ; OCW1   
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


LIST P=16F887
#include "p16f887.inc"

W_TEMP	    EQU	    0x20
STATUS_TEMP EQU	    0x21	    
	    
	    ORG	    0x00
	    GOTO    INICIO
	    ORG	    0x04
	    GOTO    ISR
	    ORG	    0x05
	    
INICIO	    BSF	    STATUS,RP1
	    BSF	    STATUS,RP0	 
	    CLRF    ANSELH
	    BCF	    STATUS,RP1
	    MOVLW   b'00000110'
	    MOVWF   TRISB
	    BCF	    OPTION_REG,INTEDG
	    BSF	    OPTION_REG,RBPU
	    BCF	    INTCON,RBIF
	    BSF	    INTCON,RBIE
	    BSF	    INTCON,GIE
	    BCF	    STATUS,RP0
	    
LOOP	    GOTO    LOOP	    

ISR	    MOVWF   W_TEMP
	    SWAPF   STATUS,W
	    MOVWF   STATUS_TEMP	 
	    ;------------------------------------	   	    
	    BTFSS   PORTB,RB2
	    GOTO    TEST1
	    BTFSS   PORTB,RB1
	    GOTO    RELE_1min
	    BCF	    PORTB,RB3
	    GOTO    FIN_ISR
TEST1	    BTFSS   PORTB,RB1
	    GOTO    RELE_3min
	    GOTO    RELE_2min	    	  	    
	    ;------------------------------------
FIN_ISR	    BCF     INTCON,RBIF
	    SWAPF   STATUS_TEMP,W
	    MOVWF   STATUS
	    SWAPF   W_TEMP,F
	    SWAPF   W_TEMP,W
	    RETFIE

RELE_1min   BSF	    PORTB,RB3
	    CALL    DELAY_1min
	    BCF	    PORTB,RB3
	    GOTO    FIN_ISR

RELE_2min   BSF	    PORTB,RB3
	    CALL    DELAY_1min
	    CALL    DELAY_1min
	    BCF	    PORTB,RB3
	    GOTO    FIN_ISR	    

RELE_3min   BSF	    PORTB,RB3
	    CALL    DELAY_1min
	    CALL    DELAY_1min
	    CALL    DELAY_1min
	    BCF	    PORTB,RB3
	    GOTO    FIN_ISR	    
	    
	    END








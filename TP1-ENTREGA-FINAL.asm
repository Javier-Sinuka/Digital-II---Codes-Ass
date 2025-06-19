    LIST P = 16F887
    #include "p16f887.inc"
    
    __CONFIG _CONFIG1, _XT_OSC & _WDTE_OFF & _MCLRE_ON & _LVP_OFF
    
		    ;***********************************************************
		    ;DECLARACION DE VARIABLES
		    ;***********************************************************
		    CBLOCK  0x20
		    ;VARIABLES PARA SALVADOS TEMPORALES
		    W_TEMP
		    STATUS_TEMP
		    ADRESH_TEMP
		    
		    ;VARIABLE DE TEMPERATURA Y TEMPERATURA MAXIMA
		    TMPR
		    TMPR_MAX_ORIGINAL
		    TMPR_MAX
		    
		    ;VARIABLES USADAS PARA LOS DISPLAYS
		    TMPR_CENTENA
		    TMPR_DECENA
		    TMPR_UNIDAD
		    TMPR_SIM
		    
		    ;VARIABLES PARA EL DELAY DEL MULTIPLEXADO
		    DEL_1
		    DEL_2
		    
		    ;VARIABLES PARA EL TECLADO
		    TECLA_CONT
		    CONT
		    TMPR_ORIGINAL
		    TMPR_CENTENA_MAX
		    TMPR_DECENA_MAX
		    TMPR_UNIDAD_MAX
		    
		    TMPR_CENTENA_TEMP
		    TMPR_DECENA_TEMP
		    TMPR_UNIDAD_TEMP
		    ENDC
		    
		    
		    ORG	    0x00
		    GOTO    INICIO
		    ORG	    0x04
		    GOTO    ISR
		    ORG	    0x05
		    
		    ;***********************************************************
		    ;CONFIGURACION DE PUERTOS
		    ;***********************************************************
CONF_PUERTOS	    MACRO
		    BANKSEL ANSEL	    ;BANCO 3
		    ;SETTEAR E<2:0> COMO DIGITALES
		    MOVLW   b'00011111'
		    MOVWF   ANSEL
		    ;LIMPIAR ANSELH PARA TODO PUERTO B DIGITAL
		    CLRF    ANSELH
		    BANKSEL TRISA	    ;BANCO 1
		    ;SETTEAR LAS PULL UP DEL PUERTO B
		    BCF	    OPTION_REG,7
		    MOVLW   b'11110000'
		    ;SETTEAR RB<0:3> COMO SALIDAS Y RB<7:4> COMO ENTRADAS
		    ;OCURRE LO MISMO CON RC<3:0> PARA EL MULTIPLEXADO
		    MOVWF   TRISB
		    MOVWF   TRISC
		    ;TODO EL PUERTO D COMO SALIDA PARA LOS DISPLAYS
		    CLRF    TRISD
		    ;SETTEAR RE<2:0> COMO SALIDA Y DEJAR RE3 COMO ENTRADA
		    MOVLW   b'11110000'
		    MOVWF   TRISE
		    BSF	    TRISA,0
		    BANKSEL PORTA	    ;BANCO 0
		    ;LIMPIO TODOS LOS PUERTOS
		    CLRF    PORTA
		    CLRF    PORTB
		    CLRF    PORTC
		    CLRF    PORTD
		    CLRF    PORTE
		    ;LAS PULLUP YA VIENEN HABILITADAS POR DEFECTO PERO SE SETTEAN
		    BANKSEL WPUB
		    MOVLW   b'11110000'
		    ENDM
		    ;***********************************************************
		    ;CONFIGURACION DE INTERRUPCIONES
		    ;***********************************************************
CONF_INT	    MACRO
		    BANKSEL PIE1	    ;BANCO 1
		    ;RB4 EL UNICO QUE GENERA INT
		    MOVLW   b'00010000'
		    MOVWF   IOCB
		    ;HABILIAR INTERRUPCIONES GLOBALES, POR PERIFERICOS Y POR PUERTO B
		    MOVLW   b'11001000'
		    MOVWF   INTCON
		    ;HABILITACION DE INT POR ADC Y RX
		    BSF	    PIE1,ADIE
		    ;BSF	    PIE1,RCIE	;ABIERTO A CAMBIO
		    ENDM
		    
		    ;***********************************************************
		    ;CONFIGURACION DEL ADC
		    ;***********************************************************
CONF_ADC	    MACRO
		    BANKSEL ADCON0  ;BANCO 0
		    ;SETTEAR LA FRECUENCIA DEL ADC Fosc/8
		    BSF	    ADCON0,ADCS0
		    BANKSEL ADCON1  ;BANCO 1
		    ;SETTEAR LA REFERENCIA POR EL PIN 5
		    BSF	    ADCON1,VCFG0
		    BANKSEL ADCON0  ;BANCO 0
		    ;PRENDER EL ADC
		    BSF	    ADCON0,ADON
		    ;NO SE SELECCIONA EL CANAL DADO QUE SE USA RA0 QUE ES 0000 EN CH
		    ENDM
		    
		    ;***********************************************************
		    ;CONFIGURACION DEL TX Y RX
		    ;***********************************************************
CONF_SERIE	    MACRO
		    BANKSEL TXSTA   ;BANCO 1
		    ;SELECCIONA UNA UNA TASA ALTA DE BAUDIOS
		    BSF	    TXSTA,BRGH
		    ;PRECARGO EL SPBRG CON 25 PARA UN BAUDIAGE DE 9600
		    MOVLW   .25
		    MOVWF   SPBRG
		    ;LIMPIO EL BIT SYNC
		    BCF	    TXSTA,4
		    BANKSEL RCSTA   ;BANCO 0
		    ;HABILITO LA RECEPCION Y TRANSMISION SERIE, ME SETTEA AUTOMATICAMENTE
		    ;LOS PINES RC6 COMO SALIDA DIGITAL Y RC7 COMO ENTRADA DIGITAL
		    BSF	    RCSTA,SPEN
		    ;DESABILITO LA RECEPCION, SE VA A HABILITAR POR TECLADO
		    BCF	    RCSTA,CREN
		    BANKSEL TXSTA   ;BANCO 1
		    ;HABILITO LA TRANSMISION SERIE.
		    BSF	    TXSTA,TXEN
		    ENDM
		    
		    ;***********************************************************
		    ;INICIO DEL PROGRAMA
		    ;***********************************************************
INICIO		    NOP
		    CONF_PUERTOS
		    CONF_INT
		    CONF_ADC
		    CONF_SERIE
		    BANKSEL PORTA
		    ;EL VALOR POR DEFAULT DE LA TMPR_MAX ES 60
		    MOVLW   .60
		    MOVWF   TMPR_MAX_ORIGINAL
		    MOVWF   TMPR_MAX
		    ;SETTEO MANUAL DE LA TEMPERATURA PARA TESTING
;		    MOVLW   .50
;		    MOVWF   TMPR
		    ;PRECARGO LOS VALORES QUE SE MUESTRAN EN LOS DISPLAYS EN 0
		    MOVLW   .0
		    MOVWF   TMPR_CENTENA
		    MOVWF   TMPR_DECENA
		    MOVWF   TMPR_UNIDAD
		    MOVLW   .12
		    MOVWF   TMPR_SIM
		    
		    ;PRENDO EL LED VERDE
		    BSF	    PORTE,RE0
		    
MAIN_CON_ADC	    BSF	    ADCON0,1
		    
MAIN_SIN_ADC	    BTFSC   RCSTA,CREN	;CHECKEO SI ESTOY EN MODO RECEPCION
		    CALL    RECEPCION
		    
		    CALL    TEST_TMPR	;TESTEO LA TEMPERATURA
		    
		    ;***********************************************************
		    ;MULTIPLEXADO DE LOS DISPLAYS
		    ;***********************************************************
		    MOVF    TMPR_CENTENA,W
		    CALL    TABLA
		    MOVWF   PORTD
		    MOVLW   b'00001000'
		    MOVWF   PORTC
		    CALL    DELAY
		    
		    BCF	    STATUS,C
		    RRF	    PORTC,F
		    MOVF    TMPR_DECENA,W
		    CALL    TABLA
		    MOVWF   PORTD
		    CALL    DELAY
		    
		    BCF	    STATUS,C
		    RRF	    PORTC,F
		    MOVF    TMPR_UNIDAD,W
		    CALL    TABLA
		    MOVWF   PORTD
		    CALL    DELAY
		    
		    BCF	    STATUS,C
		    RRF	    PORTC,F
		    MOVF    TMPR_SIM,W
		    CALL    TABLA
		    MOVWF   PORTD
		    CALL    DELAY
		    
		    ;SI ESTOY EN MODO RECEPCION NO USO EL ADC PARA NO PISAR LOS VALORES RECIBIDOS
		    BTFSS   RCSTA,CREN
		    GOTO    MAIN_CON_ADC
		    GOTO    MAIN_SIN_ADC
		    
		    ;***********************************************************
		    ;SUBRUTINA PARA LA RECEPCION DE UN DATO
		    ;***********************************************************
		    
RECEPCION	    BTFSS   PIR1,RCIF	;MIENTRAS EL CARACTER NO ESTÉ COMPLETO, NO HAGO NADA
		    RETURN
		    MOVF    RCREG,W
		    MOVWF   ADRESH_TEMP
		    MOVF    TMPR,W
		    MOVWF   TMPR_ORIGINAL
		    CALL    BCD_CONV
		    MOVF    TMPR_ORIGINAL,W
		    MOVWF   TMPR
		    RETURN

		    ;***********************************************************
		    ;PRENDER EL LED VERDE DE ENCENDIDO
		    ;***********************************************************
		    
		    BANKSEL PORTE
		    BSF	    PORTE,RE0
		    
		    ;***********************************************************
		    ;HACER LA COMPARACION CON LA TEMPERATURA MAXIMA SETTEADA
		    ;Y LA TEMPERATURA RECIBIDA POR EL ADC
		    ;***********************************************************
		    
TEST_TMPR	    NOP
		    BANKSEL PORTE
		    MOVF    TMPR_MAX,W
		    SUBWF   TMPR,W
		    BTFSC   STATUS,C
		    GOTO    TMPR1
		    GOTO    TMPR2
TMPR1		    CALL    LED_BUZZER_ON
		    GOTO    TMPR3
TMPR2		    CALL    LED_BUZZER_OFF
		    GOTO    TMPR3
TMPR3		    NOP
		    RETURN

		    ;***********************************************************
		    ;ENCENDER EL BUZZER Y EL LED
		    ;***********************************************************
LED_BUZZER_ON	    BSF	    PORTE,RE1
		    BSF	    PORTE,RE2
		    RETURN
		    
		    ;***********************************************************
		    ;APAGAR EL BUZZER Y EL LED
		    ;***********************************************************
LED_BUZZER_OFF	    BCF	    PORTE,RE1
		    BCF	    PORTE,RE2
		    RETURN
		    
		    ;***********************************************************
		    ;RUTINA DE INTERRUPCION
		    ;***********************************************************
		    
ISR		    NOP
		    ;***********************************************************
		    ;SALVADO DE CONTEXTO
		    ;***********************************************************
		    MOVWF   W_TEMP
		    SWAPF   STATUS,W
		    MOVWF   STATUS_TEMP
		    
		    ;***********************************************************
		    ;DETECTAR QUIEN GENERO LA INTERRUPCION
		    ;***********************************************************
		    BTFSC   INTCON,RBIF
		    GOTO    ISR_TECLADO
		    BTFSC   PIR1,ADIF
		    GOTO    ISR_ADC
		    
		    ;***********************************************************
		    ;SUBRUTINA DE SERVICIO AL TECLADO
		    ;***********************************************************
ISR_TECLADO	    MOVLW   b'11111110'
		    MOVWF   PORTB
		    BTFSS   PORTB,RB4
		    GOTO    SET_MAX_TMPR
		    BSF	    STATUS,C
		    RLF	    PORTB,F
		    
		    BTFSS   PORTB,RB4
		    GOTO    RESET_TMPR
		    BSF	    STATUS,C
		    RLF	    PORTB,F
		    
		    BTFSS   PORTB,RB4
		    GOTO    IO_BUZZER
		    BSF	    STATUS,C
		    RLF	    PORTB,F
		    
		    BTFSS   PORTB,RB4
		    GOTO    RX_ENABLE
		    GOTO    ISR_EXIT
		    
		    
		    ;***********************************************************
		    ;TABLA PARA LA DECODIFICACION DE LOS DISPLAYS (LOGICA POSITIVA)
		    ;***********************************************************
TABLA		    ADDWF   PCL,F
		    RETLW   0x3F
		    RETLW   0x06
		    RETLW   0x5B
		    RETLW   0x4F
		    RETLW   0x66
		    RETLW   0x6D
		    RETLW   0x7D
		    RETLW   0x07
		    RETLW   0x7F
		    RETLW   0x67
		    RETLW   0xF7
		    RETLW   0xFC
		    RETLW   0xB9
		    RETLW   0xDE
		    RETLW   0xF9
		    RETLW   0xF1		    
		    
		    ;***********************************************************
		    ;RESETEAR LA TEMPERATURA
		    ;***********************************************************
		    
RESET_TMPR	    CALL    PRESSED
		    MOVF    TMPR_MAX_ORIGINAL,W
		    MOVWF   TMPR_MAX
		    GOTO    TECLADO_EXIT
		    
		    ;***********************************************************
		    ;HABILITACION Y DESABILITACION DEL BUZZER
		    ;***********************************************************
		    
IO_BUZZER	    CALL    PRESSED
		    BANKSEL TRISE
		    BTFSS   TRISE,TRISE2
		    GOTO    BUZZER_ON
		    GOTO    BUZZER_OFF
		    
BUZZER_ON	    BSF	    TRISE,TRISE2
		    BANKSEL PORTA
		    GOTO    TECLADO_EXIT
		    
BUZZER_OFF	    BCF	    TRISE,TRISE2
		    BANKSEL PORTA
		    GOTO    TECLADO_EXIT
		    
		    ;***********************************************************
		    ;HABILITACION Y DESABILITACION DE LA RECEPCIÓN
		    ;***********************************************************
		    
RX_ENABLE	    CALL    PRESSED
		    BTFSS   RCSTA,CREN
		    GOTO    RX_ON
		    GOTO    RX_OFF
		    
RX_OFF		    BCF	    RCSTA,CREN
		    MOVLW   .12
		    MOVWF   TMPR_SIM
		    BANKSEL TXSTA
		    BSF	    TXSTA,TXEN
		    BANKSEL RCSTA
		    GOTO    TECLADO_EXIT
		    
RX_ON		    BSF	    RCSTA,CREN
		    MOVLW   .15
		    MOVWF   TMPR_SIM
		    BANKSEL TXSTA
		    BCF	    TXSTA,TXEN
		    BANKSEL RCSTA
		    GOTO    TECLADO_EXIT
		    
		    ;***********************************************************
		    ;SUBRUTINA DE SALIDA DEL TECLADO
		    ;***********************************************************
		    
TECLADO_EXIT	    BCF	    INTCON,RBIF	    ;LIMPIAR BANDERA
		    CLRF    PORTB	    ;DEVOLVER PUERTO B A ESTADO ORIGINAL
		    GOTO    ISR_EXIT	    
		    
		    ;***********************************************************
		    ;SE GRABAN 3 TECLAS EN UN POLLING DENTRO DE LA ISR
		    ;***********************************************************
		    
SET_MAX_TMPR	    CLRF    TMPR_MAX	    
		    MOVLW   .3
		    MOVWF   TECLA_CONT
		    CALL    PRESSED
		    GOTO    RECORD_TECLA
		    
RECORD_TECLA	    MOVLW   .1
		    MOVWF   CONT
		    MOVLW   b'11111110'
		    MOVWF   PORTB
		    GOTO    POLLING_TECLA
		    
POLLING_TECLA	    BTFSS   PORTB,RB7	    ;TEST DE 1, 4 Y 7
		    GOTO    SALIR_SETTING
		    INCF    CONT,F
		    
		    BTFSS   PORTB,RB6	    ;TEST DE 2, 5 Y 8
		    GOTO    SALIR_SETTING
		    INCF    CONT,F
		    
		    BTFSS   PORTB,RB5	    ;TEST DE 3, 6 Y 9
		    GOTO    SALIR_SETTING
		    INCF    CONT,F
		    
		    MOVLW   .10
		    SUBWF   CONT,W
		    BTFSC   STATUS,Z
		    GOTO    TEST_ZERO
		    
		    BSF	    STATUS,C
		    RLF	    PORTB,F
		    GOTO    POLLING_TECLA
		    
TEST_ZERO	    CLRF    CONT
		    CLRF    PORTB
		    COMF    PORTB
		    BCF	    PORTB,RB3
		    BTFSS   PORTB,RB6
		    GOTO    SALIR_SETTING
		    GOTO    RECORD_TECLA
		    
		    ;***********************************************************
		    ;PARA SALIR DE SETTEAR MAS TEMP SE DEBEN APRETAR 3 TECLAS
		    ;***********************************************************
SALIR_SETTING	    CALL    PRESSED
		    DECF    TECLA_CONT,F
		    MOVLW   .2
		    SUBWF   TECLA_CONT,W
		    BTFSC   STATUS,Z
		    GOTO    SET_CENTENA_MAX
		    MOVLW   .1
		    SUBWF   TECLA_CONT,W
		    BTFSC   STATUS,Z
		    GOTO    SET_DECENA_MAX
		    CALL    SET_UNIDAD_MAX
		    ;LIMPIO LA BANDERA DE INTERRUPCION POR RB
		    GOTO    TECLADO_EXIT
		    
		    ;***********************************************************
		    ;SETTEAR LA CENTENA
		    ;***********************************************************
SET_CENTENA_MAX	    MOVF    CONT,W
		    MOVWF   TMPR_CENTENA_MAX
		    MOVLW   .2
		    SUBWF   TMPR_CENTENA_MAX,W	;CHECK SI CENTENA ES >= 2
		    BTFSC   STATUS,C
		    CALL    MAX_VALUE_CENTENA
		    CALL    INCR_TMPR_CENTENA
		    GOTO    RECORD_TECLA
		    
MAX_VALUE_CENTENA   MOVLW   .2
		    MOVWF   TMPR_CENTENA_MAX
		    RETURN		    
		    
INCR_TMPR_CENTENA   MOVF    TMPR_CENTENA_MAX,W
		    MOVWF   TMPR_CENTENA_TEMP
		    MOVLW   .100
		    INCF    TMPR_CENTENA_MAX,F
LOOP_CENTENA	    DECFSZ  TMPR_CENTENA_MAX,F
		    GOTO    ADD_CENTENA
		    MOVF    TMPR_CENTENA_TEMP,W
		    MOVWF   TMPR_CENTENA_MAX
		    RETURN
		    
ADD_CENTENA	    ADDWF   TMPR_MAX
		    GOTO    LOOP_CENTENA
		    
		    ;***********************************************************
		    ;SETTEAR LA DECENA
		    ;***********************************************************
SET_DECENA_MAX	    MOVF    CONT,W
		    MOVWF   TMPR_DECENA_MAX
		    MOVLW   .2
		    SUBWF   TMPR_CENTENA_MAX,W	;CHECK SI CENTENA ES >= 2
		    BTFSC   STATUS,C
		    CALL    CHECK_DECENA
		    CALL    INCR_TMPR_DECENA
		    GOTO    RECORD_TECLA
		    
CHECK_DECENA	    MOVLW   .5
		    SUBWF   TMPR_DECENA_MAX,W	;CHECK SI DECENA ES >= 5
		    BTFSC   STATUS,C
		    CALL    MAX_VALUE_DECENA
		    RETURN	

MAX_VALUE_DECENA    MOVLW   .5
		    MOVWF   TMPR_DECENA_MAX
		    RETURN		    
		    
INCR_TMPR_DECENA    MOVF    TMPR_DECENA_MAX,W
		    MOVWF   TMPR_DECENA_TEMP
		    MOVLW   .10
		    INCF    TMPR_DECENA_MAX,F
LOOP_DECENA	    DECFSZ  TMPR_DECENA_MAX,F
		    GOTO    ADD_DECENA
		    MOVF    TMPR_DECENA_TEMP,W
		    MOVWF   TMPR_DECENA_MAX
		    RETURN
		    
ADD_DECENA	    ADDWF   TMPR_MAX
		    GOTO    LOOP_DECENA
		    
		    ;***********************************************************
		    ;SETTEAR LA UNIDAD
		    ;***********************************************************
SET_UNIDAD_MAX	    MOVF    CONT,W
		    MOVWF   TMPR_UNIDAD_MAX
		    MOVLW   .5
		    SUBWF   TMPR_DECENA_MAX ;CHECK SI DECENA >= 5
		    BTFSC   STATUS,C
		    CALL    CHECK_UNIDAD
		    CALL    INCR_TMPR_UNIDAD
		    RETURN
		    
INCR_TMPR_UNIDAD    INCF    TMPR_UNIDAD_MAX,F
LOOP_UNIDAD	    DECFSZ  TMPR_UNIDAD_MAX,F
		    GOTO    ADD_UNIDAD
		    RETURN
		    
ADD_UNIDAD	    INCF    TMPR_MAX,F
		    GOTO    LOOP_UNIDAD
		    
CHECK_UNIDAD	    MOVLW   .5
		    SUBWF   TMPR_UNIDAD_MAX ;CHECK SI UNIDAD >= 5
		    BTFSC   STATUS,C
		    CALL    MAX_VALUE_UNIDAD
		    RETURN
		    
MAX_VALUE_UNIDAD    MOVLW   .5
		    MOVWF   TMPR_UNIDAD_MAX
		    RETURN
		    
		    ;***********************************************************
		    ;SABER SI EL BOTON SIGUE PRESIONADO
		    ;***********************************************************
PRESSED		    BTFSS   PORTB,RB7
		    GOTO    PRESSED
		    BTFSS   PORTB,RB6
		    GOTO    PRESSED
		    BTFSS   PORTB,RB5
		    GOTO    PRESSED
		    BTFSS   PORTB,RB4
		    GOTO    PRESSED
		    RETURN

		    ;***********************************************************
		    ;SUBRUTINA DE SERVICIO AL ADC
		    ;***********************************************************
		    
ISR_ADC		    NOP
		    BANKSEL ADCON0
		    BTFSC   ADCON0,1
		    GOTO    ISR_ADC
		    MOVF    ADRESH,W
		    MOVWF   ADRESH_TEMP
		    CLRF    TMPR
		    CALL    BCD_CONV
		    BANKSEL TXSTA
		    BTFSC   TXSTA,TXEN
		    CALL    ENVIO
		    BANKSEL ADCON0
		    BCF	    PIR1,ADIF	;LIMPIAR LA BANDERA DEL ADC
		    GOTO    ISR_EXIT
		    
		    ;***********************************************************
		    ;CONVERTIR EL VALOR QUE GRABA EL ADC EN CENTENA, DECENA Y UNIDAD
		    ;SOBRE 3 REGISTROS DISTINTOS
		    ;***********************************************************
		    
BCD_CONV	    MOVLW   .0
		    MOVWF   TMPR_CENTENA
		    MOVWF   TMPR_DECENA
		    MOVWF   TMPR_UNIDAD
		    GOTO    TEST_CENTENA
		    
TEST_CENTENA	    MOVLW   .100
		    SUBWF   ADRESH_TEMP,W
		    BTFSC   STATUS,C
		    GOTO    ADD_CENTENA_ADC
		    GOTO    TEST_DECENA
		    
TEST_DECENA	    MOVLW   .10
		    SUBWF   ADRESH_TEMP,W
		    BTFSC   STATUS,C
		    GOTO    ADD_DECENA_ADC
		    GOTO    TEST_UNIDAD
		    
TEST_UNIDAD	    MOVF    ADRESH_TEMP,W
		    MOVWF   TMPR_UNIDAD
		    ADDWF   TMPR,F
		    RETURN
		    
		    
ADD_CENTENA_ADC	    MOVWF   ADRESH_TEMP
		    INCF    TMPR_CENTENA,F
		    MOVLW   .100
		    ADDWF   TMPR,F
		    GOTO    TEST_CENTENA
		    
ADD_DECENA_ADC	    MOVWF   ADRESH_TEMP
		    INCF    TMPR_DECENA,F
		    MOVLW   .10
		    ADDWF   TMPR,F
		    GOTO    TEST_DECENA
		    
		    ;***********************************************************
		    ;ENVIO DEL VALOR CONVERTIDO A LA PC
		    ;***********************************************************
ENVIO		    NOP
		    BANKSEL PORTA
		    MOVF    TMPR_CENTENA,W
		    ADDLW   .48
		    CALL    ENVIANDO
		    MOVF    TMPR_DECENA,W
		    ADDLW   .48
		    CALL    ENVIANDO
		    MOVF    TMPR_UNIDAD,W
		    ADDLW   .48
		    CALL    ENVIANDO
		    MOVLW   .42
		    CALL    ENVIANDO
		    MOVLW   .67
		    CALL    ENVIANDO
		    MOVLW   .10
		    CALL    ENVIANDO
		    MOVLW   .13
		    CALL    ENVIANDO
		    RETURN
		    
		    ;***********************************************************
		    ;POLLING HASTA QUE SE TERMINE DE ENVIAR EL DATO CARGADO
		    ;***********************************************************
ENVIANDO	    NOP
		    BANKSEL TXSTA
LOOP_ENVIO	    BTFSS   TXSTA,TRMT
		    GOTO    LOOP_ENVIO
		    BANKSEL TXREG
		    MOVWF   TXREG
		    RETURN
		    
		    ;***********************************************************
		    ;RESTAURACION DE CONTEXTO Y SALIR DE LA ISR
		    ;***********************************************************
ISR_EXIT	    SWAPF   STATUS_TEMP,W
		    MOVWF   STATUS
		    SWAPF   W_TEMP,F
		    SWAPF   W_TEMP,W
		    RETFIE
		    
		    ;***********************************************************
		    ;SUBRUTINA PARA UN DELAY DE 4mSEG
		    ;***********************************************************
DELAY		    MOVLW   .6
		    MOVWF   DEL_2
LOOP2		    MOVLW   .250
		    MOVWF   DEL_1
LOOP1		    DECFSZ  DEL_1
		    GOTO    LOOP1
		    DECFSZ  DEL_2
		    GOTO    LOOP2
		    RETURN

		    END
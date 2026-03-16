/*/
* Proyecto1.asm
*
* Creado: 04/03/26
* Autor : Edwin Eduardo Parada
* Descripción: Proyecto1. Reloj despertador 4 display de 7 segmentos
*/

.include "M328PDEF.inc"

//Variables que no estan en la ram

.equ T1VALUE = 0x1E83 //Valor de OCR1A
.equ MAX_MODES	= 3
.def MODO		= R20
.def ACTION		= R22
.def COUNTER	= R19

//Variables en memoria ram
.dseg
//Primera dirección de la RAM
.org SRAM_START

//Variables del contador del reloj

M_U:        .byte 1 // Minutos Unidades
M_D:        .byte 1 // Minutos Decenas
H_U:        .byte 1 // Horas Unidades
H_D:        .byte 1 // Horas Decenas

//Mostrar en los display

DISP1:      .byte 1
DISP2:      .byte 1
DISP3:      .byte 1
DISP4:      .byte 1

//Variables para Fecha
Dia:		.byte 1
Mes:		.byte 1

//Variables para la alarma
AL_MU:    .byte 1     // Alarma Minutos Unidades
AL_MD:    .byte 1     // Alarma Minutos Decenas
AL_HU:    .byte 1     // Alarma Horas Unidades
AL_HD:    .byte 1     // Alarma Horas Decenas
ALM_ON:     .byte 1     // 0 = Alarma Apagada, 1 = Alarma Encendida


//Acciones y mostrar
//Parpadeo de los digitos del display
BLINK:      .byte 1     // Cambiará entre 0 y 1 cada 500ms

//Parpadeo de dp.
DP_FLAG:    .byte 1    

//Bandera de cambio de minuto
MIN_FLAG:   .byte 1     //Bandera cuando cambia de minuto

ALM_EN:     .byte 1     // alarma habilitada o no


.cseg
.org 0x0000
    rjmp START          // 1. Reset

.org PCI1addr           // 3. Pin Change Interrupt Request 1 
    rjmp ISR_BOTONES

.org OC1Aaddr           // 4. Timer1 Compare Match A 
    rjmp TMR1_ISR

.org OVF0addr           // 2. Timer0 Overflow 
    rjmp TMR0_ISR


START:
    // Stack pointer
    ldi R16, LOW(RAMEND)
    out SPL, R16
    ldi R16, HIGH(RAMEND)
    out SPH, R16
	
SETUP:
	//Dehsabilitar interrupciones
	CLI

	//CONFIGURACION DE TIMER 1
	
	; Modo CTC (WGM12 = 1)
	LDI R16,	0x00
	STS TCCR1A, R16          ; WGM11=0, WGM10=0
	LDI R16, (1 << WGM12)
	STS TCCR1B, R16          //Activar moto CTC
	
	// Cargar valor de comparacion H y L
	LDI R16,	HIGH(T1VALUE)
	STS OCR1AH, R16
	LDI R16,	LOW(T1VALUE)
	STS OCR1AL, R16
	
	//Habilitar interrupción por comparación A
	LDI R16, (1 << OCIE1A)
	STS TIMSK1, R16
	
	//Prescaler 64
	LDS R16,	TCCR1B
	ORI R16,	(1<<CS11)|(1<<CS10)
	STS TCCR1B, R16

//Timer 0
    // Reloj a 1MHz
    ldi R16,   0x80
    ldi R17,   0x04
    sts CLKPR, R16
    sts CLKPR, R17

    // Iniciar timer 0 / Prescaler de 64
    ldi R16, (1 << CS01) | (1 << CS00) 
    out TCCR0B, R16
    ldi R16,	100
    out TCNT0,	R16

// Habilitar interrupción por Overflow del Timer 0
    lds  R16, TIMSK0
    ori  R16, (1 << TOIE0)
    sts  TIMSK0, R16

	//Puerto B completo como salidas para los leds indicadores de modo
	LDI R16, 0xFF
	OUT DDRB, R16

    // Puerto D completo para el display
    ldi R16,	0xFF 
    out DDRD,	R16
    
    // Deshabilitar UART para usar RX/TX
    ldi R16,	0x00
    sts UCSR0B, R16
    out PORTD,	R16 

// Puerto C: PC0 a PC4 como entradas, PC5 como salida (Buzzer)
    ldi     R16, (1 << 5)   
    out     DDRC, R16
    
    // Pull-ups en PC0-PC4
    ldi     R16, 0x1F       
    out     PORTC, R16

    // Limpiar variables 
	clr R17 //Para botones
    clr R18 //Botones tambien
	clr COUNTER //R19
	clr MODO //R20
    clr R25 //Turnos del display

    // Estado inicial de botones
    in		R22,	PINC
    andi	R22,	0x1F 

    // Mostrar LEDs iniciales apagados sin afectar botones
    in		R16,	PORTB
    andi	R16,	0x30
    or		R16,	R18
    out		PORTB,	R16
   
    // Configuracion de botones con pin change
    ldi     R16, (1 << PCIE1)
    sts     PCICR, R16
    ldi     R16, 0x1F       
    sts     PCMSK1, R16
	// Activar Interrupciones

	//Limpiar las variables de la ram
    ldi     R16, 0
    sts     M_U,		R16
    sts     M_D,		R16
    sts     H_U,		R16
    sts     H_D,		R16
    sts     DISP1,		R16
    sts     DISP2,		R16
    sts     DISP3,		R16
    sts     DISP4,		R16

	//Iniciar fecha en 01 01
	ldi     R16, 1
    sts     Dia,        R16        
    sts     Mes,        R16     

    //Seguir limpiando variables
    ldi     R16, 0	
	sts		AL_MU,		R16
	sts		AL_MD,		R16
	sts		AL_HU,		R16
	sts		AL_HD,		R16
	sts		ALM_ON,		R16
	sts		BLINK,		R16
	sts		DP_FLAG,	R16
	sts		MIN_FLAG,	R16
			

    SEI 


MAIN_LOOP:

//Cambio de minuto para alarma
    LDS     R16, MIN_FLAG
    CPI     R16, 1
    BRNE    ENRUTADOR_MODOS //Seguir si no ha cambiado de modo
    
    //Si cambio resetear bandera y seguir
    LDI     R16, 0
    STS     MIN_FLAG, R16
    RCALL   COMPROBAR_ALARMA

//Rutas para modos
ENRUTADOR_MODOS:
    cpi     MODO, 0
    brne    chk_mod_1
    rjmp    MOD_HORA
chk_mod_1:
    cpi     MODO, 1
    brne    chk_mod_2
    rjmp    MOD_FECHA
chk_mod_2:
    cpi     MODO, 2
    brne    chk_mod_3
    rjmp    MOD_ALARMA
chk_mod_3:

//Rutas modos configuracion
    cpi     MODO, 3
    brne    chk_mod_4
    rjmp    CONF_HORA
chk_mod_4:
    cpi     MODO, 4
    brne    chk_mod_5
    rjmp    CONF_FECHA
chk_mod_5:
    cpi     MODO, 5
    brne    error_modos
    rjmp    CONF_ALARMA

error_modos:
    // Seguridad
    clr     MODO
    rjmp    MAIN_LOOP

MOD_HORA:
	//Copiar el valor de las variables de hora en el registro
	cbi     PORTB, 4        ; Apagar LED 1
    cbi     PORTB, 5        ; Apagar LED 2

	LDS     R16, M_U        
    STS     DISP1, R16

	LDS		R16, M_D
	STS		DISP2, R16

	LDS		R16, H_U
	STS		DISP3, R16

	LDS		R16, H_D
	STS		DISP4, R16


    //Parpadeo de dp
	LDS     R16, BLINK      //Estado de parpadep
    STS     DP_FLAG, R16    //Bandera DP
    RJMP    MAIN_LOOP


//	MODO PARA MOSTRAR LA FECHA
MOD_FECHA:
	sbi     PORTB, 4        // Encender LED 1
    cbi     PORTB, 5        // Apagar LED 2

    LDI     R16, 1          // Punto encendido
    STS     DP_FLAG, R16    // Bandera en 1

    lds     R16, DIA        //Dia
    ldi     R17, 0          //Descenas de día

//Logica para dividir en descenas y unidades el registro de fecha
DIVIDIR_DIA:
    cpi     R16, 10         
    brlo    FIN_DIV_DIA     
    subi    R16, 10         
    inc     R17             
    rjmp    DIVIDIR_DIA     

FIN_DIV_DIA:
    
    sts     DISP3, R16      
    sts     DISP4, R17      

    lds     R16, MES        
    ldi     R17, 0          

DIVIDIR_MES:
    cpi     R16, 10         
    brlo    FIN_DIV_MES     
    subi    R16, 10         
    inc     R17             
    rjmp    DIVIDIR_MES     

FIN_DIV_MES:
   
    sts     DISP1, R16      
    sts     DISP2, R17     
    
    rjmp    MAIN_LOOP


//Modo alarma

MOD_ALARMA:
    sbi     PORTB, 5        //Led que indica el modo alarma

    //Alarma activada o desactivada
    LDS     R16, ALM_EN     //Alarma activa?
    CPI     R16, 1
    BREQ    ALARMA_ON_LEDS
    
    cbi     PORTB, 4        //Si está apagada
    RJMP    CONTINUAR_MOD_ALARMA

ALARMA_ON_LEDS:
    sbi     PORTB, 4        //Si esta encendida

CONTINUAR_MOD_ALARMA:
    // Cargar los datos al buffer de pantalla
    LDS     R16, AL_MU        
    STS     DISP1, R16
    LDS     R16, AL_MD
    STS     DISP2, R16
    LDS     R16, AL_HU
    STS     DISP3, R16
    LDS     R16, AL_HD
    STS     DISP4, R16
    
    LDI     R16, 0          
    STS     DP_FLAG, R16

    //Apagar alarma
    CPI     ACTION, 1       //Boton aumentar derecha apagar alarma
    BREQ    TOGGLE_ALARMA
    RJMP    MAIN_LOOP

TOGGLE_ALARMA:
    LDS     R16, ALM_EN     
    LDI     R17, 1
    EOR     R16, R17        
    STS     ALM_EN, R16
    LDI     ACTION, 0      
    RJMP    MAIN_LOOP


//Estado de configuración

CONF_HORA:
	cbi     PORTB, 4        // Apagar LED 1
    cbi     PORTB, 5        // Apagar LED 2
    // Parpadeo
    LDS     R16, BLINK      
    CPI     R16, 1
    BREQ    APAGAR_DISPLAYS_HORA  //Si es 1 apagar

    // Mostrar los digitos
    LDS     R16, M_U        
    STS     DISP1, R16
    LDS     R16, M_D
    STS     DISP2, R16
    LDS     R16, H_U
    STS     DISP3, R16
    LDS     R16, H_D
    STS     DISP4, R16
    RJMP    LEER_BOTONES_HORA     //Lectura de botones

APAGAR_DISPLAYS_HORA:
    LDI     R16, 16        //Apagado en la tabla de display, 00 00 para parpadeo
    STS     DISP1, R16
    STS     DISP2, R16
    STS     DISP3, R16
    STS     DISP4, R16


//Lectura de botones
LEER_BOTONES_HORA:
    CPI     ACTION, 0
    BRNE    chk_h_act1
    RJMP    FIN_CONF_HORA
chk_h_act1:
    CPI     ACTION, 1
    BRNE    chk_h_act2
    RJMP    H_AUMENTAR_MINUTOS
chk_h_act2:
    CPI     ACTION, 2
    BRNE    chk_h_act3
    RJMP    H_DISMINUIR_MINUTOS
chk_h_act3:
    CPI     ACTION, 3
    BRNE    chk_h_act4
    RJMP    H_AUMENTAR_HORAS
chk_h_act4:
    CPI     ACTION, 4
    BRNE    chk_h_err
    RJMP    H_DISMINUIR_HORAS
chk_h_err:
    RJMP    LIMPIAR_ACCION_HORA

 
 //Salto a limpiar hora
SALTO_LIMPIAR_H:
    RJMP    LIMPIAR_ACCION_HORA


    //Logica de incremento y decremento
H_AUMENTAR_MINUTOS:
    // Lógica para sumar 1 a las unidades de minuto
    LDS     R16, M_U
    INC     R16
    STS     M_U, R16
    CPI     R16, 10
    BRNE    SALTO_LIMPIAR_H //Limpiar si no  llega a 10
    
    // Cuando llega a 10 unidad en 0 y +1 la decena
    LDI     R16, 0
    STS     M_U, R16
    
    LDS     R16, M_D
    INC     R16
    STS     M_D, R16
    CPI     R16, 6
    BRNE    SALTO_LIMPIAR_H
    
    // Si llega a 60 se reinicia
    LDI     R16, 0
    STS     M_D, R16
    RJMP    LIMPIAR_ACCION_HORA

H_DISMINUIR_MINUTOS:
    LDS     R16, M_U
    CPI     R16, 0              //Comparar si la unidad de minuto es 0
    BREQ    RESTAR_DECENA_MINUTO // Si es 0 restar a la decena
    
    // Si NO es 0 solo restar 1
    DEC     R16
    STS     M_U, R16
    RJMP    LIMPIAR_ACCION_HORA

RESTAR_DECENA_MINUTO:
    //Si la unidad es 0 entonces pasa a sear un numero con 09
    LDI     R16, 9
    STS     M_U, R16
    
    // Comparar la decena
    LDS     R16, M_D
    CPI     R16, 0              //Si es 00 entonces regresara a 2359 
    BREQ    UNDERFLOW_MINUTOS
    
    // Si no es 0 es posible restar a la decena 1
    DEC     R16
    STS     M_D, R16
    RJMP    LIMPIAR_ACCION_HORA

UNDERFLOW_MINUTOS:
    //Si es 0 hacer underflow
    LDI     R16, 5
    STS     M_D, R16
    RJMP    LIMPIAR_ACCION_HORA


H_AUMENTAR_HORAS:
    // Lógica para sumar 1 a las unidades de hora
    LDS     R16, H_U
    INC     R16
    STS     H_U, R16
    
    // --- PASO 1: REVISAR EL LÍMITE DE 24 HORAS ---
    LDS     R17, H_D        //Descenas de hora
    CPI     R17, 2          //Comparar si es 2, veinte
    BRNE    H_REVISAR_10    //Si no es 2 sigue siendo 0 o 10 

    // Si las decenas son 2, el límite de las unidades es 4 
    CPI     R16, 4
    BRNE    LIMPIAR_ACCION_HORA //Si es 20 se reinicia
    
    // Si es 24 se reinicia todo a 00
    LDI     R16, 0
    STS     H_U, R16
    STS     H_D, R16
    RJMP    LIMPIAR_ACCION_HORA

    //Limites si no es 2, descenas normales
H_REVISAR_10:
    CPI     R16, 10
    BRNE    LIMPIAR_ACCION_HORA //Si no es 10 sigue aumentando

    // Si es 10 se reinicia a 0
    LDI     R16, 0
    STS     H_U, R16
    
    //Se sua 1 a la hora
    INC     R17            
    STS     H_D, R17
    RJMP    LIMPIAR_ACCION_HORA


H_DISMINUIR_HORAS:
    LDS     R16, H_U
    CPI     R16, 0            // Comparar unidad de hora 0
    BREQ    RESTAR_DECENA_HORA
    
    // Si NO es 0 se resta la unidad
    DEC     R16
    STS     H_U, R16
    RJMP    LIMPIAR_ACCION_HORA

RESTAR_DECENA_HORA:
    // Revisar la decena
    LDS     R17, H_D
    CPI     R17, 0
    BREQ    UNDERFLOW_HORAS

    // Si la decena no es 0 pasa a 9
    LDI     R16, 9
    STS     H_U, R16
    
    // 1 - a la descena
    DEC     R17
    STS     H_D, R17
    RJMP    LIMPIAR_ACCION_HORA

UNDERFLOW_HORAS:
    //Si son 00 pasa arriba a 23
    LDI     R16, 3
    STS     H_U, R16
    LDI     R16, 2
    STS     H_D, R16
    RJMP    LIMPIAR_ACCION_HORA

    //Limpiar variables
LIMPIAR_ACCION_HORA:
    LDI     ACTION, 0       


FIN_CONF_HORA:
    RJMP    MAIN_LOOP    


//CONFIGURACION DE FECHA
CONF_FECHA:
	sbi     PORTB, 4        //Encender LED 1
    cbi     PORTB, 5        // Apagar LED 2
    LDS     R16, BLINK      
    CPI     R16, 1
    BREQ    APAGAR_DISPLAYS_FECHA

	
    LDI     R16, 1
    STS     DP_FLAG, R16    //Punto encendido

    LDS     R16, DIA
    LDI     R17, 0
C_DIVIDIR_DIA:
    CPI     R16, 10
    BRLO    C_FIN_DIV_DIA
    SUBI    R16, 10
    INC     R17
    RJMP    C_DIVIDIR_DIA

C_FIN_DIV_DIA:
    // El Día a la Izquierda
    STS     DISP3, R16
    STS     DISP4, R17

    LDS     R16, MES
    LDI     R17, 0
C_DIVIDIR_MES:
    CPI     R16, 10
    BRLO    C_FIN_DIV_MES
    SUBI    R16, 10
    INC     R17
    RJMP    C_DIVIDIR_MES
C_FIN_DIV_MES:
    // El Mes a la Derecha
    STS     DISP1, R16
    STS     DISP2, R17
    
    RJMP    LEER_BOTONES_FECHA

APAGAR_DISPLAYS_FECHA:
    LDI     R16, 16         //Apagado para titileo
    STS     DISP1, R16
    STS     DISP2, R16
    STS     DISP3, R16
    STS     DISP4, R16

//LEER BOTONES
LEER_BOTONES_FECHA:
    CPI     ACTION, 0
    BRNE    chk_f_act1
    RJMP    FIN_CONF_FECHA
chk_f_act1:
    CPI     ACTION, 1
    BRNE    chk_f_act2
    RJMP    F_AUMENTAR_DIAS
chk_f_act2:
    CPI     ACTION, 2
    BRNE    chk_f_act3
    RJMP    F_DISMINUIR_DIAS
chk_f_act3:
    CPI     ACTION, 3
    BRNE    chk_f_act4
    RJMP    F_AUMENTAR_MESES
chk_f_act4:
    CPI     ACTION, 4
    BRNE    chk_f_err
    RJMP    F_DISMINUIR_MESES
chk_f_err:
    RJMP    LIMPIAR_ACCION_FECHA

//Salto a fecha
SALTO_LIMPIAR_F:
    RJMP    LIMPIAR_ACCION_FECHA


//Logica de fecha
F_AUMENTAR_DIAS:
    LDS     R16, Dia
    INC     R16
    
    // Buscar el límite del mes actual en la tabla
    LDS     R17, Mes
    DEC     R17             // Restar en 1 por el limte que empieza en la direccion 0
    LDI     ZH, HIGH(TABLA_Fechas * 2)
    LDI     ZL, LOW(TABLA_Fechas * 2)
    ADD     ZL, R17
    BRCC    no_carry_fd1
    INC     ZH
no_carry_fd1:
    LPM     R18, Z          //Registro con el maximo de días 
    
    // Comparar si nos pasamos del límite
    CP      R18, R16
    BRSH    GUARDAR_DIA     // Si Límite es mayor al Día, seguir
    
    LDI     R16, 1          //Si es menor cambiar de día
GUARDAR_DIA:
    STS     Dia, R16
    RJMP    LIMPIAR_ACCION_FECHA

F_DISMINUIR_DIAS:
    LDS     R16, Dia
    CPI     R16, 1          //Día 1
    BRNE    RESTAR_DIA_NORMAL

    //Si es el día 1 restar mes y pasar al limite de ese mes
    LDS     R17, Mes
    DEC     R17
    LDI     ZH, HIGH(TABLA_Fechas * 2)
    LDI     ZL, LOW(TABLA_Fechas * 2)
    ADD     ZL, R17
    BRCC    no_carry_fd2
    INC     ZH
no_carry_fd2:
    LPM     R16, Z          //Cargar limite del mes
    RJMP    GUARDAR_DIA

RESTAR_DIA_NORMAL:
    DEC     R16
    RJMP    GUARDAR_DIA

//Logicca de meses del 1 al 12
F_AUMENTAR_MESES:
    LDS     R16, Mes
    INC     R16
    CPI     R16, 13
    BRNE    GUARDAR_MES
    LDI     R16, 1          //aumenta de 1 a 12 y regresa a 1
    RJMP    GUARDAR_MES

F_DISMINUIR_MESES:
    LDS     R16, Mes
    CPI     R16, 1
    BRNE    RESTAR_MES_NORMAL
    LDI     R16, 12         //decrementa de 12 a 1 y regresa a 12
    RJMP    GUARDAR_MES
RESTAR_MES_NORMAL:
    DEC     R16

GUARDAR_MES:
    STS     Mes, R16
	//Guardar día

	//Ajustar día segun mes
AJUSTAR_DIA_AL_MES:
    LDS     R17, Mes
    DEC     R17
    LDI     ZH, HIGH(TABLA_Fechas * 2)
    LDI     ZL, LOW(TABLA_Fechas * 2)
    ADD     ZL, R17
    BRCC    no_carry_fd3
    INC     ZH
no_carry_fd3:
    LPM     R18, Z          //Limite del nuevo mes
    
    LDS     R16, Dia
    CP      R18, R16        
    BRSH   SALTO_LIMPIAR_F //Si el limite se cumple seguir

    //Si el limite es mayor, cortar 
    STS     Dia, R18

   //Limpiar
LIMPIAR_ACCION_FECHA:
    LDI     ACTION, 0       

FIN_CONF_FECHA:
    RJMP    MAIN_LOOP




//CONFIGURACION DE LA ALARMA
CONF_ALARMA:
	cbi     PORTB, 4        // Apagar LED 1
    sbi     PORTB, 5        // Encender LED 2

	//Parpadeo
    LDS     R16, BLINK      
    CPI     R16, 1
    BREQ    APAGAR_DISPLAYS_ALARMA

    // Mostrar digitos
    LDS     R16, AL_MU        
    STS     DISP1, R16
    LDS     R16, AL_MD
    STS     DISP2, R16
    LDS     R16, AL_HU
    STS     DISP3, R16
    LDS     R16, AL_HD
    STS     DISP4, R16
    RJMP    LEER_BOTONES_ALARMA

APAGAR_DISPLAYS_ALARMA:
    LDI     R16, 16         //Apagado parpadeo
    STS     DISP1, R16
    STS     DISP2, R16
    STS     DISP3, R16
    STS     DISP4, R16


//LEER BOTONES
LEER_BOTONES_ALARMA:
    CPI     ACTION, 0
    BRNE    chk_a_act1
    RJMP    FIN_CONF_ALARMA
chk_a_act1:
    CPI     ACTION, 1
    BRNE    chk_a_act2
    RJMP    A_AUMENTAR_MINUTOS
chk_a_act2:
    CPI     ACTION, 2
    BRNE    chk_a_act3
    RJMP    A_DISMINUIR_MINUTOS
chk_a_act3:
    CPI     ACTION, 3
    BRNE    chk_a_act4
    RJMP    A_AUMENTAR_HORAS
chk_a_act4:
    CPI     ACTION, 4
    BRNE    chk_a_err
    RJMP    A_DISMINUIR_HORAS
chk_a_err:
    RJMP    LIMPIAR_ACCION_ALARMA

 
SALTO_LIMPIAR_A:
    RJMP    LIMPIAR_ACCION_ALARMA



//Logica de minutos (identico a reloj)
A_AUMENTAR_MINUTOS:
    LDS     R16, AL_MU
    INC     R16
    STS     AL_MU, R16
    CPI     R16, 10
    BRNE   SALTO_LIMPIAR_A
    
    LDI     R16, 0
    STS     AL_MU, R16
    
    LDS     R16, AL_MD
    INC     R16
    STS     AL_MD, R16
    CPI     R16, 6
    BRNE    SALTO_LIMPIAR_A
    
    LDI     R16, 0
    STS     AL_MD, R16
    RJMP    SALTO_LIMPIAR_A

A_DISMINUIR_MINUTOS:
    LDS     R16, AL_MU
    CPI     R16, 0
    BREQ    A_RESTAR_DEC_MIN
    
    DEC     R16
    STS     AL_MU, R16
    RJMP    SALTO_LIMPIAR_A

A_RESTAR_DEC_MIN:
    LDI     R16, 9
    STS     AL_MU, R16
    
    LDS     R16, AL_MD
    CPI     R16, 0
    BREQ    A_UNDERFLOW_MIN
    
    DEC     R16
    STS     AL_MD, R16
    RJMP    LIMPIAR_ACCION_ALARMA

A_UNDERFLOW_MIN:
    LDI     R16, 5
    STS     AL_MD, R16
    RJMP    LIMPIAR_ACCION_ALARMA

//LOGICA DE HORAS (identico a reloj)
A_AUMENTAR_HORAS:
    LDS     R16, AL_HU
    INC     R16
    STS     AL_HU, R16
    
    LDS     R17, AL_HD
    CPI     R17, 2
    BRNE    A_REVISAR_10

    CPI     R16, 4
    BRNE    SALTO_LIMPIAR_A
    
    LDI     R16, 0
    STS     AL_HU, R16
    STS     AL_HD, R16
    RJMP    LIMPIAR_ACCION_ALARMA

A_REVISAR_10:
    CPI     R16, 10
    BRNE    SALTO_LIMPIAR_A
    
    LDI     R16, 0
    STS     AL_HU, R16
    INC     R17
    STS     AL_HD, R17
    RJMP    LIMPIAR_ACCION_ALARMA

A_DISMINUIR_HORAS:
    LDS     R16, AL_HU
    CPI     R16, 0
    BREQ    A_RESTAR_DEC_HORA
    
    DEC     R16
    STS     AL_HU, R16
    RJMP    LIMPIAR_ACCION_ALARMA

A_RESTAR_DEC_HORA:
    LDS     R17, AL_HD
    CPI     R17, 0
    BREQ    A_UNDERFLOW_HORA

    LDI     R16, 9
    STS     AL_HU, R16
    DEC     R17
    STS     AL_HD, R17
    RJMP    LIMPIAR_ACCION_ALARMA

A_UNDERFLOW_HORA:
    LDI     R16, 3
    STS     AL_HU, R16
    LDI     R16, 2
    STS     AL_HD, R16

LIMPIAR_ACCION_ALARMA:
    LDI     ACTION, 0      

FIN_CONF_ALARMA:
    RJMP    MAIN_LOOP


//Logica de parpadeo de numeros
APAGAR_PANTALLA:
    LDI     R16, 16         //Apagado para parpadeo
    STS     DISP1, R16
    STS     DISP2, R16
    STS     DISP3, R16
    STS     DISP4, R16
    rjmp    MAIN_LOOP


//MULTIPLEXACION DE LOS DISPLAY
TURNO_DISPLAY_1:
    rcall   CARGAR_DISPLAY1
    sbi     PORTB, 0        
    rjmp    MAIN_LOOP       

TURNO_DISPLAY_2:
    rcall   CARGAR_DISPLAY2
    sbi     PORTB, 1       
    rjmp    MAIN_LOOP

TURNO_DISPLAY_3:
    rcall   CARGAR_DISPLAY3
    sbi     PORTB, 2        
    rjmp    MAIN_LOOP

TURNO_DISPLAY_4:
    rcall   CARGAR_DISPLAY4
    sbi     PORTB, 3        
    rjmp    MAIN_LOOP


// DIGITOS DEL DISPLAY

//Unidades de minutos
CARGAR_DISPLAY1:
    ldi     ZH, HIGH(TABLA_7SEG * 2)
    ldi     ZL, LOW(TABLA_7SEG * 2)
	//Colocar el valor de la variable segun el modo en el display
	LDS		R16, DISP1
    add     ZL, R16
    brcc    no_carry1
    inc     ZH

no_carry1:
    lpm     R24, Z  
    out     PORTD, R24
    ret

//Descenas de minutos
CARGAR_DISPLAY2:
    ldi     ZH, HIGH(TABLA_7SEG * 2)
    ldi     ZL, LOW(TABLA_7SEG * 2)
	LDS		R16, DISP2
    add     ZL, R16
    brcc    no_carry2
    inc     ZH

no_carry2:
    lpm     R24, Z
	
	//Dp
	LDS		R16, DP_FLAG
	SBRC	R16,	0
	ORI		R24, 0x80
	  
    out     PORTD, R24
    ret

//Unidades de Horas // 1 , 0 , 3 
CARGAR_DISPLAY3:
    ldi     ZH, HIGH(TABLA_7SEG * 2)
    ldi     ZL, LOW(TABLA_7SEG * 2)
	LDS		R16, DISP3
    add     ZL, R16
    brcc    no_carry3
    inc     ZH

no_carry3:
    lpm     R24, Z 

	//Dp
	LDS		R16, DP_FLAG
	SBRC	R16,	0
	ORI		R24, 0x80

    out     PORTD, R24
    ret

//Descenas de horas 0 , 1 , 2
CARGAR_DISPLAY4:
    ldi     ZH, HIGH(TABLA_7SEG * 2)
    ldi     ZL, LOW(TABLA_7SEG * 2)
	LDS		R16, DISP4
    add     ZL, R16
    brcc    no_carry4
    inc     ZH

no_carry4:
    lpm     R24, Z  
    out     PORTD, R24
    ret

//Rutina de interrupcion timer 0
TMR0_ISR:
    push R16           
    in   R16, SREG
    push R16

    // Recargar el timer para los 3.5ms
    ldi  R16, 200
    out  TCNT0, R16

    // a) Apagar todos los displays
    cbi  PORTB, 0
    cbi  PORTB, 1
    cbi  PORTB, 2
    cbi  PORTB, 3

    // b) Cambiar turno
    inc  R25
    andi R25, 0x03

    // c) Enrutador
    cpi  R25, 0
    breq T_DISP_1
    cpi  R25, 1
    breq T_DISP_2
    cpi  R25, 2
    breq T_DISP_3
    rjmp T_DISP_4

T_DISP_1:
    rcall CARGAR_DISPLAY1
    sbi  PORTB, 0
    rjmp FIN_TMR0
T_DISP_2:
    rcall CARGAR_DISPLAY2
    sbi  PORTB, 1
    rjmp FIN_TMR0
T_DISP_3:
    rcall CARGAR_DISPLAY3
    sbi  PORTB, 2
    rjmp FIN_TMR0
T_DISP_4:
    rcall CARGAR_DISPLAY4
    sbi  PORTB, 3

FIN_TMR0:
    pop  R16            // Restaurar contexto
    out  SREG, R16
    pop  R16
    reti

//Rutina de interrupción timer 1
TMR1_ISR:
    push r16            
    in   r16, SREG      
    push r16            

	//Logica de contador
	RCALL REVISAR_TIEMPOS
	brne salirisr

salirisr:
    pop  r16            
    out  SREG, r16
    pop  r16           
    reti               


//Contar los tiempos
REVISAR_TIEMPOS:
    //Logica de parpadeo cada 500ms de los leds
    LDS     R16, BLINK
    LDI     R17, 1
    EOR     R16, R17        //Alternar bits entre 0 y 1
    STS     BLINK, R16

   //Pausar tiempo para editar la hora
    CPI     MODO, 3         //Verificar modo
    BRNE    chk_stop_m4     //Reevisar modo
    RJMP    salir_tiempos   //saltar a revisar tiempos

chk_stop_m4:
    CPI     MODO, 4        	//Verificar modo
    BRNE    continuar_reloj	//Reevisar modo
    RJMP    salir_tiempos  	//saltar a revisar tiempos

continuar_reloj:

    // 1 Minuto
    INC     COUNTER
    cpi     COUNTER, 1      // (Cambiar a 120 para 1 minuto real)
    breq    calc_min_u      // Avanzar si llega al limite
    rjmp    salir_tiempos   //Si no llega, repetir

calc_min_u:
	clr     COUNTER

    //Bandera de 1 minuto para alarma
    LDI     R16, 1
    STS     MIN_FLAG, R16
    // ------------------------------------------

    // Unidades de minutos
    LDS     R16, M_U
    inc     R16
    STS     M_U, R16
    cpi     R16, 10         
    breq    calc_min_d
    rjmp    salir_tiempos

calc_min_d:
    LDI     R16, 0             
    STS     M_U, R16        // Reinicia unidades

    // Decenas de minutos
    LDS     R16, M_D
    inc     R16
    STS     M_D, R16     
    cpi     R16, 6          
    breq    calc_hora_u
    rjmp    salir_tiempos

calc_hora_u:
    LDI     R16, 0
    STS     M_D, R16        // Reinicia decenas

//LOGICA PARA LAS HORAS
    // Aumentar unidades de horas
    LDS     R16, H_U
    inc     R16
    STS     H_U, R16

    // Comparar si las desceas son 2
    LDS     R16, H_D
    cpi     R16, 2
    BRNE    Caso2

    // Si las decenas son 2, revisar si ya es 24
    LDS     R16, H_U
    cpi     R16, 4
    breq    nuevo_dia
    rjmp    salir_tiempos

Caso2:
    //Revisar si las unidades aún no son 10
    LDS     R16, H_U
    cpi     R16, 10
    breq    calc_hora_d
    rjmp    salir_tiempos

calc_hora_d:
    LDI     R16, 0
    STS     H_U, R16        // Se resetean las unidades

    //Incrementar descenas de horas
    LDS     R16, H_D
    inc     R16
    STS     H_D, R16
    rjmp    salir_tiempos

//LOGICA DE DIAS Y MESES
nuevo_dia:
    LDI     R16, 0
    STS     H_U, R16        // Horas a 00
    STS     H_D, R16

    // Incremento en fecha
    LDS     R16, Dia
    INC     R16
    STS     Dia, R16

    // Limite del mes (Buscar en tabla)
    LDS     R17, Mes       
    DEC     R17           

    LDI     ZH, HIGH(TABLA_Fechas * 2) 
    LDI     ZL, LOW(TABLA_Fechas * 2) 
    ADD     ZL, R17
    BRCC    NO_CARRYMS
    INC     ZH

NO_CARRYMS:
    LPM     R18, Z

    // Comparar Día vs Límite del Mes
    LDS     R16, Dia
    CP      R18, R16
    BRSH    salir_tiempos   ; Si Límite >= Día, salir

    // Si se paso el limite volver a 1
    LDI     R16, 1
    STS     Dia, R16

    // Incrementar mes
    LDS     R16, Mes
    INC     R16
    STS     Mes, R16

    // Revisamos si pasa al mes 13
    CPI     R16, 13
    breq    reset_anio
    rjmp    salir_tiempos

reset_anio:
    LDI     R16, 1
    STS     Mes, R16

salir_tiempos:
    ret



//PCIN INTERRUPCION DE BOTONES
ISR_BOTONES:
    push    R16
    in      R16, SREG
    push    R16
    push    R19

    in      R16, PINC       //Leer puerto C

	//Filtro antirrebote
    cpi     R16, 0x1F       
    breq    SALTO_SALIR    

// Boton de cambio de modo y alarma
    SBRC    R16, 0
    RJMP    REV_PUSH2
    
    //VErificar si apagar la alarma o cambiar modo
    LDS     R17, ALM_ON
    CPI     R17, 1
    BRNE    CAMBIAR_MODO_NORMAL
    
    //Si es alarma apagar buzzer
    LDI     R17, 0
    STS     ALM_ON, R17     ; Apagamos la bandera de estado
    CBI     PORTC, 5        ; ¡Apagamos el Buzzer!
    RJMP    SALIR_BOTONES   ; Salimos SIN cambiar de modo en la pantalla

CAMBIAR_MODO_NORMAL:
    INC     MODO
    CPI     MODO, 6
    BRNE    SALIR_BOTONES
    LDI     MODO, 0
    RJMP    SALIR_BOTONES

SALTO_SALIR:
    RJMP    SALIR_BOTONES

   
REV_PUSH2:
    SBRC    R16, 1
    RJMP    REV_PUSH3
    LDI     ACTION, 1
    RJMP    SALIR_BOTONES

    
REV_PUSH3:
    SBRC    R16, 2
    RJMP    REV_PUSH4
    LDI     ACTION, 2
    RJMP    SALIR_BOTONES
    
    
REV_PUSH4:
    SBRC    R16, 3
    RJMP    REV_PUSH5
    LDI     ACTION, 3
    RJMP    SALIR_BOTONES

    
REV_PUSH5:
    SBRC    R16, 4
    RJMP    SALIR_BOTONES
    LDI     ACTION, 4

SALIR_BOTONES:
    pop     R19
    POP     R16
    OUT     SREG, R16
    POP     R16
    RETI


//RUTINA PARA LA ALARMA
COMPROBAR_ALARMA:

	LDS     R16, ALM_EN
    CPI     R16, 1
    BRNE    FIN_COMPROBAR   //Alarma 1 o 0

    LDS     R16, H_D
    LDS     R17, AL_HD
    CP      R16, R17
    BRNE    FIN_COMPROBAR

    LDS     R16, H_U
    LDS     R17, AL_HU
    CP      R16, R17
    BRNE    FIN_COMPROBAR

    LDS     R16, M_D
    LDS     R17, AL_MD
    CP      R16, R17
    BRNE    FIN_COMPROBAR

    LDS     R16, M_U
    LDS     R17, AL_MU
    CP      R16, R17
    BRNE    FIN_COMPROBAR

	//Si las condiciones no lo sacaron encender la alarma
    LDI     R16, 1
    STS     ALM_ON, R16     //Variable de alarma
    SBI     PORTC, 5        //EAncender buzzer PC5

FIN_COMPROBAR:
    RET


// TABLA DE FECHAS
TABLA_Fechas:
	// enero  febr  marz abril mayo   junio jul   agos   sep  oct  nov dec
	.DB 0x1F, 0x1C, 0x1F, 0x1E, 0x1F, 0x1E, 0x1F, 0x1F, 0x1E, 0x1F, 0x1E, 0x1F

// TABLA DE BITS DEL DISPLAY
TABLA_7SEG:
    .DB 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F, 0x77, 0x7C, 0x39, 0x5E, 0x79, 0x71, 0x00
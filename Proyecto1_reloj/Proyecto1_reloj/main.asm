/*/
* Proyecto1.asm
*
* Creado: 04/03/26
* Autor : Edwin Eduardo Parada
* Descripción: Proyecto1. Reloj despertador 4 display de 7 segmentos
*/

.include "M328PDEF.inc"
.equ T1VALUE = 0x1E83 //Valor de OCR1A
.equ MAX_MODES	= 3
.def MODO		= R20
.def COUNTER	= R19
.def ACTION		= R22

//Registros para el tiempo
.def M_U  = R21   ; Unidades de Minuto (0-9)
.def M_D  = R23   ; Decenas de Minuto (0-5)
.def H_U = R26   ; Unidades de Hora (0-9)
.def H_D = R27   ; Decenas de Hora (0-2)

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
	
	; Prescaler 64
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


//DEFINICION DE SALIDAS Y ENTRADAS
	// Puertos PB0 y PB1 como salidas // Transistores de displays
    //sbi DDRB, 0     
    //sbi DDRB, 1
	//sbi DDRB, 2     
    //sbi DDRB, 3
	// Para los leds

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

    // Puerto C: PC0 a PC4 como entradas
    ldi R16,	0x00
    out DDRC,	R16
    //cbi DDRC,	4
    //cbi DDRC,	5

    // Pull-ups internos
	LDI R16, 0x1F
	OUT PORTC, R16
    //sbi PORTC, 4   
    //sbi PORTC, 5   

	//Puerto c como salida para el buzzer
	SBI DDRB, 5

    // Limpiar variables a 0
	clr R17
    clr R18
	clr R19  
    clr R23 
    clr R25
	clr	R21
	clr	R23
	clr	R26
	clr	R27

    // Estado inicial de botones
    in		R22,	PINC
    andi	R22,	0x1F 

    // Mostrar LEDs iniciales apagados sin afectar botones
    in		R16,	PORTB
    andi	R16,	0x30
    or		R16,	R18
    out		PORTB,	R16
   
    // Configuracion de botones con pin change
    ldi R16, (1 << PCIE1)
    sts PCICR, R16
    ldi R16, (1 << PCINT12) | (1 << PCINT13)
    sts PCMSK1, R16
	// Activar Interrupciones


	//Bloque de codigo para pruebas

//; --- INICIALIZAR HORA A LAS 23:59 PARA PRUEBAS ---
//    ldi     R16, 1
//    mov     M_U, R16        ; Unidades de minuto = 9
//    
//    ldi     R16, 1
//    mov     M_D, R16        ; Decenas de minuto = 5
//    
//    ldi     R16, 3
//    mov     H_U, R16        ; Unidades de hora = 3
//    
//    ldi     R16, 2
//    mov     H_D, R16        ; Decenas de hora = 2


    SEI 


MAIN_LOOP:
    // Revisamos en qué modo estamos
    cpi     MODO, 0
    breq    ESTADO_MOSTRAR_HORA
    
    // Si no es ninguno de los anteriores, regresamos por seguridad
    rjmp    MAIN_LOOP

ESTADO_MOSTRAR_HORA:
    // Aquí (más adelante) copiaremos la hora a los displays
    // Por ahora, solo regresamos al loop principal de forma segura:
    rjmp    MAIN_LOOP

TURNO_DISPLAY_1:
    rcall   CARGAR_DISPLAY1
    sbi     PORTB, 0        // ¡Enciende Transistor 1!
    rjmp    MAIN_LOOP       // ¡Vuelve a esperar 10ms!

TURNO_DISPLAY_2:
    rcall   CARGAR_DISPLAY2
    sbi     PORTB, 1        // ¡Enciende Transistor 2!
    rjmp    MAIN_LOOP

TURNO_DISPLAY_3:
    rcall   CARGAR_DISPLAY3
    sbi     PORTB, 2        // ¡Enciende Transistor 3!
    rjmp    MAIN_LOOP

TURNO_DISPLAY_4:
    rcall   CARGAR_DISPLAY4
    sbi     PORTB, 3        // ¡Enciende Transistor 4!
    rjmp    MAIN_LOOP


// DIGITOS DEL DISPLAY

//Unidades de minutos
CARGAR_DISPLAY1:
    ldi     ZH, HIGH(TABLA_7SEG * 2)
    ldi     ZL, LOW(TABLA_7SEG * 2)
    add     ZL, M_U
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
    add     ZL, M_D
    brcc    no_carry2
    inc     ZH

no_carry2:
    lpm     R24, Z  
    out     PORTD, R24
    ret

//Unidades de Horas // 1 , 0 , 3 
CARGAR_DISPLAY3:
    ldi     ZH, HIGH(TABLA_7SEG * 2)
    ldi     ZL, LOW(TABLA_7SEG * 2)
    add     ZL, H_U
    brcc    no_carry1
    inc     ZH

no_carry3:
    lpm     R24, Z  
    out     PORTD, R24
    ret

//Descenas de horas 0 , 1 , 2
CARGAR_DISPLAY4:
    ldi     ZH, HIGH(TABLA_7SEG * 2)
    ldi     ZL, LOW(TABLA_7SEG * 2)
    add     ZL, H_D
    brcc    no_carry2
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
    push r16            ; Guardamos r16 en el Stack
    in   r16, SREG      ; Leemos el registro de estado
    push r16            ; Lo guardamos en el Stack

	//Logica de contador
	RCALL REVISAR_TIEMPOS
	brne salirisr

salirisr:
    pop  r16            ; Recuperamos SREG
    out  SREG, r16
    pop  r16            ; Recuperamos r16
    reti                ; Regreso de interrupción (RETI es obligatorio)

//Contar los tiempos
REVISAR_TIEMPOS:
	// Contar 2 500ms para 1 segundo

	// 1 Minuto
    INC		COUNTER
    cpi     COUNTER, 1   //debería ser 120  // Esperar a que sea 1 minuto
	BRNE	salir_tiempos
 
    clr     COUNTER

	// Unidades de minutos
    inc     M_U
    cpi		M_U, 10         //Esperar a que el display 1 cuente a 10 para aumentar el display 2
    BRNE	salir_tiempos

    clr     M_U             // Reinicia unidades a 0

	// Descenas de minutos
    inc     M_D     
    cpi     M_D, 6          // ¿Llegó a 6 el display 2? (Para llegar a 59)
    BRNE	salir_tiempos

	clr     M_D

//Logica para las horas (24) Las horas: Unidades de Horas // Puede contar 2 veces a 10 y la siguiente vez solo debería contar 4
	//Caso 1 de horas

	//Aumentar unidades de horas
	inc		H_U
	//Comparar si las descenas son 2
    cpi     H_D, 2
	//Si las descenas aún no son 2 salta a caso 2      
	BRNE	Caso2

	//Si las descenas son 2 
	//Compara si las unidades son 4 (por las 24 horas)
	cpi		H_U, 4
	//Si aun no llega a 4 sigue cotando horas 
	BRNE	salir_tiempos
	//Si ya esta en 4 las unidades resetea el día
	rjmp	nuevo_dia

	//Si las descenas de hora aún no están en 2
Caso2:
	//comparar si las unidades de hora ya contaron a 10
	cpi		H_U, 10
	//Si aún no, siguen contando
	BRNE	salir_tiempos

	//Si ya llegaron a 10 se resetean las unidades
    clr     H_U
	//Y se incrementan las descenas de horas
	inc		H_D
	//Repite el ciclo para aumentar nuevamente
	rjmp	salir_tiempos

	//Resetear el día reiniciando las horas a 00
nuevo_dia:
	clr		H_U
	clr		H_D
salir_tiempos:
	ret


// PCINT Puerto (Cambio de modos y modificar fecha puerto C)

//Logica por implementar
ISR_BOTONES:
    push R16
    in R16, SREG
    push R16
    push R19

    in R17, PINC
    andi R17, 0x1F      

    sbrs R19, 4         
    rjmp REVISAR_DEC

    inc R18
    andi R18, 0x0F   

REVISAR_DEC:
    sbrs R19, 5         
    rjmp ACTUALIZAR_LEDS

    dec R18
    andi R18, 0x0F   

ACTUALIZAR_LEDS:
    in R16, PORTC
    andi R16, 0xF0         
    or R16, R18
    out PORTC, R16

    pop R19
    pop R16
    out SREG, R16
    pop R16
    reti

// TABLA DE FECHAS
TABLA_Fechas:
	// enero  febr  marz abril mayo   junio jul   agos   sep  oct  nov dec
	.DB 0x1F, 0x1C, 0x1F, 0x1E, 0x1F, 0x1E, 0x1F, 0x1F, 0x1E, 0x1F, 0x1E, 0x1F

	/*
	Idea actual para esto:
	hacer un ANDY cuando inicia cada mez con el valor extraido del stack entonces hará 
	overflow y underflow la fecha al llegar al limite de su andi.
	*/

	//Maximo de días de cada mes, utilizado para cambiar de mes.
	//Mes de 1 a 12 y reinicio. formato fecha
	//Día/Mes

// TABLA DE BITS DEL DISPLAY
TABLA_7SEG:
    .DB 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F, 0x77, 0x7C, 0x39, 0x5E, 0x79, 0x71
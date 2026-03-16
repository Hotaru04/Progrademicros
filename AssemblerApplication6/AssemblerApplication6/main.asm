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
.def COUNTER	= R21
.def ACTION		= R22

.cseg
.org 0x0000
    rjmp START          // 1. Reset

//.org PCI1addr           // 3. Pin Change Interrupt Request 1 
//    rjmp ISR_BOTONES
//
//.org OC1Aaddr           // 4. Timer1 Compare Match A 
//    rjmp TMR1_ISR

//.org OVF0addr           // 2. Timer0 Overflow 
//    rjmp TMR0_ISR


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
    ldi R16,	200
    out TCNT0,	R16


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
    sei 


MAIN_LOOP:
    // 1. Esperar el overflow (10ms aprox)
    in      R16, TIFR0
    sbrs    R16, TOV0 
    rjmp    MAIN_LOOP

    // Limpiar bandera de overflow y reiniciar el timer
    ldi     R16, (1 << TOV0)
    out     TIFR0, R16
    ldi     R16, 200
    out     TCNT0, R16


Multiplexacion:
// a) Apagar los 4 transistores (PB0, PB1, PB2, PB3)
	cbi     PORTB, 0
	cbi     PORTB, 1
	cbi     PORTB, 2
	cbi     PORTB, 3

	// b) Cambiar turno (0 a 3)
	inc     R25
	andi    R25, 0x03
	
	// c) Enrutador de displays
	cpi     R25, 0
	breq    TURNO_DISPLAY_1
	cpi     R25, 1
	breq    TURNO_DISPLAY_2
	cpi     R25, 2
	breq    TURNO_DISPLAY_3
	rjmp    TURNO_DISPLAY_4 
 

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
    add     ZL, R23
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
    add     ZL, R23
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
    add     ZL, R23
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
    add     ZL, R23
    brcc    no_carry2
    inc     ZH

no_carry4:
    lpm     R24, Z  
    out     PORTD, R24
    ret


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
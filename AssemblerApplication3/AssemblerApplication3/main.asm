/*m
* Laboratorio3.asm
*
* Creado: 16/02/26
* Autor : Edwin Eduardo Parada
* Descripción: Laboratorio 3. Contador de 4 bits con LEDs utilizando 
* interrupciones On-Change (PCINT) y botones con pull-ups internos.
*/
/****************************************/
// Encabezado (Definición de Registros, Variables y Constantes)

.include "M328PDEF.inc"

// Registros
.def temp       = R16
.def botones    = R17 
.def contador4b = R18 // Contador de 4 bits (LEDs)
.def cambios    = R19
.def anterior   = R22 

.cseg
// Vector de Reset
.org 0x0000
    rjmp START

//.org PCI1addr
	//RJMP ISR_BOTONES

///.org OVD0addr
	//RJMP TIME

// Vector de Interrupción para Pin Change
.org PCI1addr
    rjmp ISR_BOTONES

START:
    // Stack pointer
    ldi temp, LOW(RAMEND)
    out SPL, temp
    ldi temp, HIGH(RAMEND)
    out SPH, temp

SETUP:
    // Reloj a 1MHz
    ldi R16, 0x80
    sts CLKPR, R16
    ldi R16, 0x04
    sts CLKPR, R16

    //Iniciar timer 0
    ldi temp, (1 << CS01) | (1 << CS00) //Prescaler 64
    out TCCR0B, temp
    ldi temp, 100
    out TCNT0, temp

	//Puerto D para el display
    ldi R16, 0xFF 
    out DDRD, R16
    
    // Deshabilitar UART para poder usar PD0 (RX) y PD1 (TX)
    ldi R16, 0x00
    sts UCSR0B, R16
    out PORTD, R16 //Display apagado

    // Puerto C: PC0-PC3 como salidas y PC4-PC5 como entradas
    ldi R16, 0x0F
    out DDRC, R16
    
    cbi DDRC, 4
    cbi DDRC, 5
    // Pull-ups internos
    sbi PORTC, 4   
    sbi PORTC, 5    

    // Limpiar variables del contador
    clr contador4b

    // Tomar el estado inicial de los botones para la primera comparación
    in anterior, PINC
    andi anterior, 0x30 

    // Mostrar el contador inicial (Apagado = 0)
    in R16, PORTC
    andi R16, 0xF0
    or R16, contador4b
    out PORTC, R16

   
    // CONFIGURACIÓN DE INTERRUPCIONES ON-CHANGE (PCINT)
    // 1. Habilitar el bloque de interrupciones para el Puerto C (PCIE1)
    ldi R16, (1 << PCIE1)
    sts PCICR, R16

    // 2. Desenmascarar (Activar) los pines específicos PC4 y PC5 (PCINT12 y 13)
    ldi temp, (1 << PCINT12) | (1 << PCINT13)
    sts PCMSK1, temp

    // 3. Habilitar las interrupciones globales
    SEI 
    // ---------------------------------------------------------

	clr R18
    clr R20
	clr R21

MAIN_LOOP:

// Esperar el desbordamiento del Timer (10ms)
    in      R16, TIFR0
    sbrs    R16, TOV0 
    rjmp    MAIN_LOOP

    //Limpiar bandera de overflow y reiniciar el timer
    ldi     R16, (1 << TOV0) 
    out     TIFR0, R16
    ldi     temp, 100
    out     TCNT0, R16

    //Esperar a que pase 1 segundo
    inc     R20
    cpi     R20, 100      // Esperar 100 veces 10ms
    brne    MAIN_LOOP       // Esperar a que pase 1 segundo

    //Luego de 1 segundo
    clr     R20           //Reiniciar cuenta de latidos
    rcall   ACTUALIZAR_DISPLAY   //Avanzar contador de LEDs


    rjmp MAIN_LOOP

// RUTINA DE INTERRUPCIÓN (Debe ser lo más corta posible)

ISR_BOTONES:
//Proteger sreg
    push R16
    in R16, SREG
    push R16
    push cambios

    // 2. Leer el estado actual de los pines
    in botones, PINC
    andi botones, 0x30      // Aislar PC4 y PC5

    // 3. Detección de Flanco de Bajada (Cambio de 1 -> 0)
    mov cambios, anterior
    eor cambios, botones    // XOR: detecta cambios
    and cambios, anterior   // AND toma los que pasan de 1 a 0

    mov anterior, botones

    sbrs cambios, 4         // Si el bit 4 no cambió, salta la suma
    rjmp REVISAR_DEC

    inc contador4b
    andi contador4b, 0x0F   // Limitar a 4 bits (0-15)

REVISAR_DEC:
    // 6. Evaluar si fue el botón de DECREMENTO (PC5)
    sbrs cambios, 5         // Si el bit 5 no cambió, salta la resta
    rjmp ACTUALIZAR_LEDS

    dec contador4b
    andi contador4b, 0x0F   // mascara 4 bits

ACTUALIZAR_LEDS:
    // Mostrar los leds
    in R16, PORTC
    andi R16, 0xF0       // mascara para pull_Ups
    or R16, contador4b
    out PORTC, R16

    // 8. Restaurar SREG y registros para devolver el CPU a su estado original
    pop cambios
    pop R16
    out SREG, R16
    pop R16

    // Salir de la interrupción
    reti


// Display de 7 segmentos

ACTUALIZAR_DISPLAY:
    // Apuntar al lugar de memoria
	ANDI R21, 0x0F
    ldi     ZH, HIGH(TABLA_7SEG * 2)
    ldi     ZL, LOW(TABLA_7SEG * 2)
    add     ZL, R21
    brcc    no_carry
    inc     ZH

no_carry:
    // Extraer de la memoria el codigo para encender el led
    lpm     R24, Z  
    // Encender el estado del display
    out     PORTD, R24
	INC R21
    ret



// Apuntar al lugar de memoria
	ANDI R21, 0x0F
    ldi     ZH, HIGH(TABLA_7SEG * 2)
    ldi     ZL, LOW(TABLA_7SEG * 2)
    add     ZL, R21
    brcc    no_carry
    inc     ZH

no_carry:
    // Extraer de la memoria el codigo para encender el led
    lpm     R24, Z  
    // Encender el estado del display
    out     PORTD, R24
	INC R21
    ret

// TABLA DE DATOS DEL DISPLAY
TABLA_7SEG:
    .DB 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F, 0x77, 0x7C, 0x39, 0x5E, 0x79, 0x71
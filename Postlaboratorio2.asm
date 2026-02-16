/*
* Laboratorio2.asm
*
* Creado: 09/02/26
* Autor : Edwin Eduardo Parada
* Descripción: Laboratorio 2 programación de microcontroladores, display de 7 segmentos y utilización de timer 0 para contador.
*/
/****************************************/
// Encabezado (Definición de Registros, Variables y Constantes)
// Registros


.include "M328PDEF.inc"

//Registros
.def temp       = R16
.def botones    = R17 
.def contador4b = R18 //Contador de 4 bits
.def cambios    = R19
.def loops      = R20 // Contador de (1 segundo)
.def target     = R21 // El número límite (0-15) mostrado en el Display
.def anterior   = R22 
.def display_pt = R24 // Patrón para el display

.cseg
.org 0x0000
    rjmp START

START:
    //Stack pointer
    ldi temp, LOW(RAMEND)
    out SPL, temp
    ldi temp, HIGH(RAMEND)
    out SPH, temp

SETUP:
    //Reloj
    ldi temp, 0x80
    sts CLKPR, temp
    ldi temp, 0x04
    sts CLKPR, temp

    //Iniciar timer 0
    ldi temp, (1 << CS01) | (1 << CS00) //Prescaler 64
    out TCCR0B, temp
    ldi temp, 100
    out TCNT0, temp

	//Puerto D para el display
    ldi temp, 0xFF 
    out DDRD, temp    
    
    // Deshabilitar UART para poder usar PD0 (RX) y PD1 (TX)
    ldi temp, 0x00
    sts UCSR0B, temp
    out PORTD, temp //Display apagado

    //Led para tpggle
    sbi DDRB, 0    

    //Puerto C ledds y botones
    ldi temp, 0x0F
    out DDRC, temp
    cbi DDRC, 4
    cbi DDRC, 5
    sbi PORTC, 4   
    sbi PORTC, 5    

    //Limpiar variables
    clr loops
    clr contador4b
    clr target

    //Leer botones en 0
    in anterior, PINC
    andi anterior, 0x30 

    //Estado inicial del display en 0 y contador apagado
    rcall ACTUALIZAR_DISPLAY
    rcall MOSTRAR_4B


MAIN_LOOP:
    // Esperar el desbordamiento del Timer (10ms)
    in      temp, TIFR0
    sbrs    temp, TOV0 
    rjmp    MAIN_LOOP

    //Limpiar bandera de overflow y reiniciar el timer
    ldi     temp, (1 << TOV0) 
    out     TIFR0, temp
    ldi     temp, 100
    out     TCNT0, temp

    //Leer botones y antirrebote
    in      botones, PINC
    andi    botones, 0x30   // Mascara para PC4 y PC5

    mov     cambios, anterior
    eor     cambios, botones
    and     cambios, anterior
    mov     anterior, botones

    sbrc    cambios, 4      // Si se presiono PC4
    rcall   INC_TARGET
    
    sbrc    cambios, 5      // Si se presiono PC5
    rcall   DEC_TARGET

    //Esperar a que pase 1 segundo
    inc     loops
    cpi     loops, 100      // Esperar 100 veces 10ms
    brne    MAIN_LOOP       // Esperar a que pase 1 segundo

    //Luego de 1 segundo
    clr     loops           ; Reiniciar cuenta de latidos
    rcall   INCREMENTO_4B   ; Avanzar contador de LEDs

    rjmp    MAIN_LOOP



//Acciones de los botones inc y dec

INC_TARGET:
    inc     target
    andi    target, 0x0F    ; Mantener entre 0 y 15
    rcall   ACTUALIZAR_DISPLAY
    ret

DEC_TARGET:
    dec     target
    andi    target, 0x0F
    rcall   ACTUALIZAR_DISPLAY
    ret

//SUBRUTINA DEL CONTADOR 4 BITS Y TOGGLE

INCREMENTO_4B:
    inc     contador4b
    
    // Comparar contador de display con contador de 4 bits
    cp      target, contador4b
    brsh    MOSTRAR_4B      // Si es igual o mayor mostrar los bits

	// Cuando pasa el limite se reinicia el contador y se hace toggle al led
    clr     contador4b      // Reiniciar contador 4b
    sbi     PINB, 0         //

MOSTRAR_4B:
    //Encender bits de contador4b
    in      temp, PORTC
    andi    temp, 0xF0      
    or      temp, contador4b
    out     PORTC, temp
    ret


// Display de 7 segmentos

ACTUALIZAR_DISPLAY:
    // Apuntar al lugar de memoria
    ldi     ZH, HIGH(TABLA_7SEG * 2)
    ldi     ZL, LOW(TABLA_7SEG * 2)
    add     ZL, target
    brcc    no_carry
    inc     ZH


no_carry:
    // Extraer de la memoria el codigo para encender el led
    lpm     display_pt, Z  

    // Encender el estado del display
    out     PORTD, display_pt
    ret

// TABLA DE DATOS DEL DISPLAY
TABLA_7SEG:
    .DB 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F, 0x77, 0x7C, 0x39, 0x5E, 0x79, 0x71
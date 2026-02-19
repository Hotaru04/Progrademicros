/*
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
    ldi temp, 0x80
    sts CLKPR, temp
    ldi temp, 0x04
    sts CLKPR, temp

    // Puerto C: PC0-PC3 como salidas y PC4-PC5 como entradas
    ldi temp, 0x0F
    out DDRC, temp
    
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
    in temp, PORTC
    andi temp, 0xF0
    or temp, contador4b
    out PORTC, temp

   
    // CONFIGURACIÓN DE INTERRUPCIONES ON-CHANGE (PCINT)
    // 1. Habilitar el bloque de interrupciones para el Puerto C (PCIE1)
    ldi temp, (1 << PCIE1)
    sts PCICR, temp

    // 2. Desenmascarar (Activar) los pines específicos PC4 y PC5 (PCINT12 y 13)
    ldi temp, (1 << PCINT12) | (1 << PCINT13)
    sts PCMSK1, temp

    // 3. Habilitar las interrupciones globales
    sei 
    // ---------------------------------------------------------

MAIN_LOOP:

    rjmp MAIN_LOOP



// RUTINA DE INTERRUPCIÓN (Debe ser lo más corta posible)

ISR_BOTONES:
//Proteger sreg
    push temp
    in temp, SREG
    push temp
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
    in temp, PORTC
    andi temp, 0xF0       // mascara para pull_Ups
    or temp, contador4b
    out PORTC, temp

    // 8. Restaurar SREG y registros para devolver el CPU a su estado original
    pop cambios
    pop temp
    out SREG, temp
    pop temp

    // Salir de la interrupción
    reti
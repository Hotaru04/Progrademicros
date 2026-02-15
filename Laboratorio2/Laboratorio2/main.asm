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

.def temp       = R16
.def lectura    = R17 
.def anterior   = R18
.def cambios    = R19
//.def contador1  = R20
.def display_pattern = R24


.include "M328PDEF.inc"     // Include definitions specific to ATMega328P
.dseg
.org    SRAM_START
//variable_name:     .byte   1   // Memory alocation for variable_name:     .byte   (byte size)

.cseg
.org 0x0000
 /****************************************/
// Configuración de la pila
LDI     R16, LOW(RAMEND)
OUT     SPL, R16
LDI     R16, HIGH(RAMEND)
OUT     SPH, R16
/****************************************/
// Configuracion MCU
// ... (Tus def y encabezados aquí) ...
.def contador1  = R20  ; ¡Descomentado!

// ... (Stack pointer setup) ...

SETUP:
	// Setting de prescaler
	LDI temp, 0x80
	STS CLKPR, temp
	LDI temp, 0x04
	STS CLKPR, temp

	// Inicializar el timer
	LDI temp, (1 << CS01)|(1 << CS00)
	OUT TCCR0B, temp   ; CORREGIDO: TCCR0B
	LDI temp, 100
	OUT TCNT0, temp

	// Salidas del Puerto D y B
	LDI temp, 0xFC 
	OUT DDRD, temp    
	SBI DDRB, 0     

	// Salidas del puerto C (contador de 4 bits)
	LDI temp, 0x0F     ; AJUSTADO: 0x0F (0000 1111) pone PC0-PC3 como salidas
	OUT DDRC, temp     ; CORREGIDO: Faltaba esta línea

	// Entradas del puerto C, 2 Botones
	CBI DDRC, 4
	CBI DDRC, 5
	SBI PORTC, 4    
	SBI PORTC, 5    

	CLR contador1      ; CORREGIDO: Usando el alias

MAIN_LOOP:
	IN      temp, TIFR0
	SBRS    temp, TOV0 ; CORREGIDO: TOV0
	RJMP    MAIN_LOOP
	
	// Limpiar bandera de forma segura
	LDI     temp, (1 << TOV0) 
	OUT     TIFR0, temp

	// Reiniciar Timer
	LDI     temp, 100
	OUT     TCNT0, temp

	// Lógica de conteo (50 vueltas)
	INC     contador1
	CPI     contador1, 50
	BRNE    MAIN_LOOP
	
	CLR     contador1
	
	// Hacer Toggle (Invertir) el estado de PC0
	SBI     PINC, PC0  ; Esto funciona perfecto en AVR modernos para invertir salidas
	
	RJMP    MAIN_LOOP



/****************************************/
// NON-Interrupt subroutines

/****************************************/
// Interrupt routines

/****************************************/
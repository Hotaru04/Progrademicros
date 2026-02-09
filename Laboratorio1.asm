/*
* Laboratorio1.asm
*
* Creado: 28/01/2026
* Autor : Edwin Parada 
* Descripción: Contador sumador binario de 4 bits
*/
/****************************************/
// Encabezado (Definición de Registros, Variables y Constantes)
.include "M328PDEF.inc"     // Include definitions specific to ATMega328P
.dseg
.org    SRAM_START
//variable_name:     .byte   1   // Memory alocation for variable_name:     .byte   (byte size)

//Variables para los rejistros

.def temp       = R16
.def lectura    = R17 
.def anterior   = R18
.def cambios    = R19
.def contador1  = R20
.def contador2  = R21
.def suma_temp  = R22
.def aux        = R23 

.cseg
.org 0x0000
    rjmp START

START:
    // Stack Pointer
    ldi temp, LOW(RAMEND)
    out SPL, temp
    ldi temp, HIGH(RAMEND)
    out SPH, temp

	//Configuración del MSU
SETUP:

	//Configuración del reloj a 1MHZ

	ldi temp, (1 << CLKPCE)
	sts CLKPR, temp

	LDI temp, 0b10000000
	STS CLKPR, temp
	//Iniciar Timer
	LDI temp, 0b00000100
	sts CLKPR, temp

    //Salidas del contador 1 y bajo del contador 2
    ldi temp, 0xFC //11111100
    out DDRD, temp

    //Salidas altas de contador 2 y configuración de PB5 para el led smd para carry
    sbi DDRB, 0
    sbi DDRB, 1
    sbi DDRB, 5 
    cbi PORTB, 5 //Carry inicialmente apagado
    
	//Puerto C pines 0,1,2,3 para salidas de los led de resultado
	ldi temp, 0x0F 
    out DDRC, temp
    
	//Pull up para los botones
    ldi temp, 0x30 0011 0000
    out PORTC, temp

    //Entradas de los botones de incremento y decremento
    cbi DDRB, 2
    cbi DDRB, 3
    cbi DDRB, 4

	//Pull up ´para los botones
    sbi PORTB, 2
    sbi PORTB, 3
    sbi PORTB, 4

    //Limpiar contadores
    clr contador1
    clr contador2
    
    //Leer el estado de los botones como apagados

    rcall BOTONES
    mov anterior, lectura

MAIN_LOOP:
    //Lectura de botones
    rcall BOTONES
    //Compara la lectura acual con la lectura anterior
    cp lectura, anterior
    breq MAIN_LOOP
	//Si es igual regresa a hacer la lectura

    //Si no es igual espera un tiempo y vuelve a hacer la lectura para confirmar
    rcall DELAY_MS
    rcall BOTONES 

    ; 4. Detectar Flanco de Bajada
    mov cambios, anterior
    eor cambios, lectura
    and cambios, anterior 

    ; 5. Actualizar Anterior
    mov anterior, lectura

	
	//Acciones en los contadores


    //Revisión de los botones de los contadores para aumentar o decrementar.

	//Boton contador 1 incremento
    sbrc cambios, 0
    rcall ACCION_INC_C1

    //Boton contador 1 decremento
    sbrc cambios, 1
    rcall ACCION_DEC_C1

    //Boton contador 2 incremento
    sbrc cambios, 2
    rcall ACCION_INC_C2

    //Boton contador 1 incremento
    sbrc cambios, 3
    rcall ACCION_DEC_C2

    //Boton que suma ambos contadores
    sbrc cambios, 4
    rcall CALCULAR_SUMA

    //Enciende o apaga  los leds de los contadores segun el boton precionado
    rcall MOSTRAR_CONTADORES
    
	//Regresa a main_loop para la siguiente acción de los botones
    rjmp MAIN_LOOP

; ---------------------------------------------------
; LEER_BOTONES_UNIFICADOS
; Mapa de bits resultante en R17:
; Bit 0: PB2 (Inc C1)
; Bit 1: PB3 (Dec C1)
; Bit 2: PB4 (Inc C2)
; Bit 3: PC4 (Dec C2)
; Bit 4: PC5 (SUMA)
; ---------------------------------------------------
BOTONES:
    //Leer el puerto B, 3 Botones
    in temp, PINB

	//And inmediato para poner una mascara y usar los bits 2,3,4 del registros (00011100)
    andi temp, 0x1C

	//Mueve los bits 2 posicíones a la derecha para facilitar el encendido de los leds al cargar el registro en el puerto C.
    lsr temp 
    lsr temp
	//Bits ahora en posición (00000111)
    
    //Leer los botones del puerto C, Boton de decremento de contador 1 y Botón de suma.
    in aux, PINC       
    andi aux, 0x30  //Cargar (00011000)

	//Mueve los bit 1 posicion para conicidir con (00011000)
    lsr aux

	//El or permite unificar los bits de los 5 Botones y finalmente es (00011111)
    or temp, aux       
    mov lectura, temp  
    ret

//CONTADORES 1,2

//Incrementa o decrementa el valor del contador
//ANDI sirve para limitar el contador a 4 bits, si el contador psaria a (00010000) el andi lo vuelve nuevamente (00000000)
ACCION_INC_C1:
    inc contador1
    andi contador1, 0x0F
    ret

ACCION_DEC_C1:
    dec contador1
    andi contador1, 0x0F
    ret

ACCION_INC_C2:
    inc contador2
    andi contador2, 0x0F
    ret

ACCION_DEC_C2:
    dec contador2
    andi contador2, 0x0F
    ret

//SUMA

CALCULAR_SUMA:
	//Mueve a suma_temp el registro del contador 1 usando mov y usando add suma ambos registros
    mov suma_temp, contador1
    add suma_temp, contador2

    //Leer el estado actual del PORC (Leds)
    in aux, PORTC     
    andi aux, 0xF0     //Borra la parte baja del registro C(Donde estan los led) y mantiene la superior(los botones)
    
    mov temp, suma_temp
    andi temp, 0x0F   //Solo resultado de 0 a 15 (00001111)
    or aux, temp      //Or para encender los leds al usar aux
    out PORTC, aux    //Encender los led

    ; Si la suma > 15, el bit 4 de suma_temp será 1 (ej. 16 = 10000)
    sbrc suma_temp, 4  ; Si el bit 4 está limpio (0), salta la instrucción
    rjmp ENCENDER_CARRY
    
    ; Si no hubo salto, apagar carry
    cbi PORTB, 5
    ret

ENCENDER_CARRY:
    sbi PORTB, 5
    ret

	//Encender los contadores

MOSTRAR_CONTADORES:
    //Contador 1
    in aux, PORTD
    andi aux, 0x03     
    mov temp, contador1
    lsl temp 
    lsl temp           
    or aux, temp       

	//Contador 2
    mov temp, contador2
    andi temp, 0x03    
    lsl temp           
    lsl temp
    lsl temp
    lsl temp
    lsl temp
    lsl temp
    or aux, temp       
    out PORTD, aux     

    //Contador 2 alto
    in aux, PORTB      
    andi aux, 0xFC 
    
    mov temp, contador2
    andi temp, 0x0C    
    lsr temp           
    lsr temp           
    
    or aux, temp       
    out PORTB, aux     
    ret

DELAY_MS:
    ldi  r23, 40
DL1:ldi  r24, 200
DL2:dec  r24
    brne DL2
    dec  r23
    brne DL1
    ret
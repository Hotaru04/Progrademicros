/*
 * Contador8bits.c
 *
 * Descripción: Contador 8-bits.
 */

#include <avr/io.h>
#include <avr/interrupt.h>


// --- Prototipos de funciones ---
void setup(void);

volatile uint8_t contador = 0; 

int main(void)
{
    //Leds como salidas
    DDRD = 0xFF;
    PORTD = 0x00;

    //Botones
    DDRC &= ~((1 << PC2) | (1 << PC3));
    PORTC |= (1 << PC2) | (1 << PC3);
	
	//Timer 0 cada 10ms
    TCCR0A = (1 << WGM01);              // Activar Modo CTC
    OCR0A = 156;                        // 156 (10ms)
    TIMSK0 = (1 << OCIE0A);             // Habilitar la interrupción
    
    //Iniciar Timer
    TCCR0B = (1 << CS02) | (1 << CS00); 

    //Interrupciones globales
    sei();

    
    while (1)
    {
    }
}

//Rutina de interrupción
ISR(TIMER0_COMPA_vect)
{
	//Variables de estado
    static uint8_t estado_inc_ant = 1;
    static uint8_t estado_dec_ant = 1;

    //Leer pines
    uint8_t estado_inc_act = (PINC & (1 << PC2)) ? 1 : 0;
    uint8_t estado_dec_act = (PINC & (1 << PC3)) ? 1 : 0;

	//Incremento
    if (estado_inc_act == 0 && estado_inc_ant == 1) 
    {
        contador++;
        PORTD = contador;
    }
    estado_inc_ant = estado_inc_act; // Guardar estado para los próximos 10ms

     // Decremento
    if (estado_dec_act == 0 && estado_dec_ant == 1) 
    {
        contador--;
        PORTD = contador;
    }
    estado_dec_ant = estado_dec_act;
}
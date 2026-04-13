/*
 * Laboratorio 4 ADC.c
 *
 * Descripción: 
 * 1. Contador Binario de 8 bits y ADC con display y alarma.
 */

#define F_CPU 16000000UL

#include <avr/io.h>
#include <avr/interrupt.h>

volatile uint8_t contador_leds = 0;       
volatile uint8_t valor_potenciometro = 0; 

// Tabla de 7 segmentos para Cátodo Común (0 a F)
const uint8_t tabla_7seg[16] = {
    0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 
    0x7F, 0x6F, 0x77, 0x7C, 0x39, 0x5E, 0x79, 0x71
};

void setup(void);
uint8_t leerADC_8bits(uint8_t canal);

//Main
int main(void)
{
    setup(); 
    sei(); 

    while (1)
    {
        valor_potenciometro = leerADC_8bits(6); 
        
        //Alarma en PD7
        if (valor_potenciometro > contador_leds)
        {
            PORTD |= (1 << PD7);  // Encender Alarma
        }
        else
        {
            PORTD &= ~(1 << PD7); // Apagar Alarma
        }
    }
}

//Configuracion de pines 
void setup(void)
{
    //Deshabilitar UART PD0 y PD1 
    UCSR0B = 0x00; 

    // Display PD0-PD6 y Alarma PD7
    DDRD = 0xFF;  //Todo el puerto D como salida
    PORTD = 0x00;  //Inicialmente apagado

    // 2. Transistores PB0-PB1 y Contador PB2-PB5
    DDRB |= 0x3F; //Todo el puerto B como salidas
    PORTB = 0x00; //Inicialmente apagado

    // Contador PC0-PC3
    DDRC |= 0x0F;  //Salidas 1
	// Botones PC4-PC5
    DDRC &= ~((1 << PC4) | (1 << PC5)); //Entradas 0

    PORTC &= ~0x0F; //Apagados
	                     
    PORTC |= (1 << PC4) | (1 << PC5);   // Pull-ups

    // Configuracion alineación a la izquierda 8 bits más significativos
    ADMUX = (1 << REFS0) | (1 << ADLAR); 
    ADCSRA = (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0);

    // 5. Timer0
    TCCR0A = (1 << WGM01);              
    OCR0A = 78;                         
    TIMSK0 = (1 << OCIE0A);             
    TCCR0B = (1 << CS02) | (1 << CS00); 
}

//Lectura de ADC
uint8_t leerADC_8bits(uint8_t canal)
{
    ADMUX = (ADMUX & 0xF0) | (canal & 0x0F); 
    ADCSRA |= (1 << ADSC);
    while (ADCSRA & (1 << ADSC));
    return ADCH; 
}

// Timer 0 interrupcion
ISR(TIMER0_COMPA_vect)
{
    static uint8_t turno = 0;

    //Estado de puerto C (leds y excluir botones)
    uint8_t estado_pullups = PORTC & ((1 << PC4) | (1 << PC5));
	//Botones
    PORTC = estado_pullups | ((contador_leds >> 4) & 0x0F);

    uint8_t portb_nuevo = ((contador_leds & 0x0F) << 2); 

	//Multiplexado
    // Guardar estado de la alarma
    uint8_t estado_alarma = PORTD & (1 << PD7); 

    if (turno == 0)
    {
        //Display Izquierdo
        PORTD = estado_alarma | tabla_7seg[(valor_potenciometro >> 4) & 0x0F];
        portb_nuevo |= (1 << PB0);  
        turno = 1;
    }
    else
    {
        //Display derecho
        PORTD = estado_alarma | tabla_7seg[valor_potenciometro & 0x0F];
        portb_nuevo |= (1 << PB1);  
        turno = 0;
    }

    PORTB = (PORTB & 0xC0) | portb_nuevo; 

    //Leer botones
    static uint8_t ant_inc = 1;
    static uint8_t ant_dec = 1;

    uint8_t act_inc = (PINC & (1 << PC4)) ? 1 : 0;
    uint8_t act_dec = (PINC & (1 << PC5)) ? 1 : 0;

    if (act_inc == 0 && ant_inc == 1) {
        contador_leds++; 
    }
    ant_inc = act_inc;

    if (act_dec == 0 && ant_dec == 1) {
        contador_leds--; 
    }
    ant_dec = act_dec;
}
/*
 * Prelaboratorio5.c
 * Descripción: ADC potenciometro y PWM servomotor
 */

#define F_CPU 16000000UL

#include <avr/io.h>
#include <util/delay.h>
#include "ServoTimer1.h" // Importar libreria

//Prototipos
void ADC_Init(void);
uint8_t leerADC(uint8_t canal);

int main(void)
{
    //Funcion ADC
    ADC_Init();  
	//Funcion PWM  
    Servo_Init(); 
	
    while (1)
    {
        // Leer potenciómetro
        uint8_t lectura = leerADC(7); 
        
        // Actualizar Servomotor usando la librería
        Servo_SetPosition(lectura);
        
        _delay_ms(15); 
    }
}

// ADC configuracion
void ADC_Init(void)
{
    ADMUX = (1 << REFS0) | (1 << ADLAR); 
    ADCSRA = (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0); 
}

//Lectura ADC
uint8_t leerADC(uint8_t canal)
{
    ADMUX = (ADMUX & 0xF0) | (canal & 0x0F);
    ADCSRA |= (1 << ADSC);
    while (ADCSRA & (1 << ADSC));
    return ADCH; 
}
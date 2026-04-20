/*
 * Laboratorio_5.cpp
 *
 * Created: 20/04/2026 00:55:17
 * Author : MineS
 */ 

#define F_CPU 16000000UL

#include <avr/io.h>
#include <util/delay.h>
#include <avr/interrupt.h>

#include "ServoTimer1.h" //Libreria servo PWM timer 1
#include "ServoTimer2.h" //Libeeria servo PWM timer 2
#include "ManualPWM.h" //Libreria PWM manual

//Prototipos
void ADC_Init(void);
uint8_t leerADC(uint8_t canal);

int main(void)
{
	// Funcion ADC
	ADC_Init();
	
	// Funcion PWM
	Servo_Init1(); // Enciende PB1
	Servo_Init2(); // Enciende PB3
	ManualPWM_Init(); 
	
	sei();
	
	while (1)
	{
		// Leer potenciómetros
		uint8_t lectura1 = leerADC(6);
		uint8_t lectura2 = leerADC(7);
		uint8_t lectura3 = leerADC(5);
		
		// Actualizar Servomotores independientes
		Servo_SetPosition1(lectura1);
		Servo_SetPosition2(lectura2);
		ManualPWM_Set(lectura3);
		
		_delay_ms(15);
	}
}

// ADC configuracion
void ADC_Init(void)
{
	ADMUX = (1 << REFS0) | (1 << ADLAR);
	ADCSRA = (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0);
}

// Lectura ADC
uint8_t leerADC(uint8_t canal)
{
	ADMUX = (ADMUX & 0xF0) | (canal & 0x0F);
	ADCSRA |= (1 << ADSC);
	while (ADCSRA & (1 << ADSC));
	return ADCH;
}

/*
 * Libreria servomotores timer 1 y 2
 *
 * Created: 4/05/2026 15:59:09
 * Author: Edwin Parada
 * Descripcion: Libreria pwm para servomotores Timer 1 y 2
 */ 

#include "Servospwm.h"

void Servos_Init(void)
{
	//COnfiguracion
	DDRB |= (1 << PB1) | (1 << PB2) | (1 << PB3);
	DDRD |= (1 << PD3);

	//Configuracion de Timer 1, 50Hz
	TCCR1A = (1 << COM1A1) | (1 << COM1B1) | (1 << WGM11);
	TCCR1B = (1 << WGM13) | (1 << WGM12) | (1 << CS11);
	ICR1 = 39999;
	//Ticks
	// Reposo
	OCR1A = 1000;
	OCR1B = 1000;

	// Configuracion de Timer 2 61Hz
	TCCR2A = (1 << COM2A1) | (1 << COM2B1) | (1 << WGM21) | (1 << WGM20);
	TCCR2B = (1 << CS22) | (1 << CS21) | (1 << CS20);
	//Reposo
	OCR2A = 16;
	OCR2B = 16;
}

//Mapeo de los servomotores
void Servo1_Set(uint8_t valor_adc) { OCR1A = 1000 + ((uint32_t)valor_adc * 4000) / 255; }
void Servo2_Set(uint8_t valor_adc) { OCR1B = 1000 + ((uint32_t)valor_adc * 4000) / 255; }
void Servo3_Set(uint8_t valor_adc) { OCR2A = 8 + ((uint16_t)valor_adc * 31) / 255; }
void Servo4_Set(uint8_t valor_adc) { OCR2B = 8 + ((uint16_t)valor_adc * 31) / 255; }
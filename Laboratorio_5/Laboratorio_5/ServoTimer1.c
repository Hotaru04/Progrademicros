/*
 * ServoTimer1.c
 *
 * Created: 20/04/2026 00:55:49
 *  Author: MineS
 */ 
#include "ServoTimer1.h"

// Configurar hardware para AMBOS servos en el Timer 1
void Servo_Init1(void)
{
	// 1. Configurar Pines PB1 (Servo 1) y PB2 (Servo 2) como salidas
	DDRB |= (1 << PB1);

	// 2. Encender COM1A1 (para PB1) y COM1B1 (para PB2)
	TCCR1A = (1 << COM1A1) | (1 << WGM11);
	
	// WGM13 = 1, WGM12 = 1. CS11 = 1 (Prescaler de 8)
	TCCR1B = (1 << WGM13) | (1 << WGM12) | (1 << CS11);
	
	// El Tope de los 50Hz (20ms)
	ICR1 = 39999;
	
	// Posición inicial 0 para ambos
	OCR1A = 1000;
}

// Función exclusiva para el Servo 1 (PB1)
void Servo_SetPosition1(uint8_t valor_adc1)
{
	uint16_t valor_pwm1 = 1000 + ((uint32_t)valor_adc1 * 4000) / 255;
	OCR1A = valor_pwm1;
}

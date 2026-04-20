/*
 * ServoTimer2.c
 *
 * Created: 20/04/2026 00:56:04
 *  Author: MineS
 */ 
/*
 * ServoTimer2.c

 */

#include "ServoTimer2.h"

//Configuarar el hardware para el servo

void Servo_Init2(void)
{
	//Configurar Pin PB3 Como salida 
	DDRB |= (1 << PB3);
	
	TCCR2A = (1 << COM2A1) | (1 << WGM21) | (1 << WGM20);
	
	TCCR2B = (1 << CS22 ) | (1 << CS21) | (1 << CS20);
	
	// 8 tics 0 grados
	OCR2A = 8;
}

void Servo_SetPosition2(uint8_t valor_adc2)
{
	uint8_t valor_pwm2 = 8 + ((uint8_t)valor_adc2*31)/255;
	
	OCR2A = valor_pwm2;
}
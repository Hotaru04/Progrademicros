/*
 * PWMdc.c
 *
 * Created: 4/05/2026 15:58:10
 * Author: Edwin Parada
 * Descripcion: PWM manual para motores DC
 */ 

#include "PWMdc.h"
#include <avr/interrupt.h>

volatile uint8_t pwm_count = 0;
volatile uint32_t ms_ticks = 0;
volatile uint8_t duty_pd4 = 0;
volatile uint8_t duty_pd5 = 0;
volatile uint8_t duty_pd6 = 0;
volatile uint8_t duty_pd7 = 0;

void SoftPWM_Init(void)
{
	// Configurar pines
	DDRD |= (1 << PD4) | (1 << PD5) | (1 << PD6) | (1 << PD7);
	PORTD &= ~((1 << PD4) | (1 << PD5) | (1 << PD6) | (1 << PD7));

	// Configuracion de timer 0
	TCCR0A = 0x00;
	TCCR0B = (1 << CS00);
	TIMSK0 |= (1 << TOIE0);
}

void SoftPWM_SetDuty(uint8_t pin, uint8_t duty)
{
	if (pin == 4) duty_pd4 = duty;
	else if (pin == 5) duty_pd5 = duty;
	else if (pin == 6) duty_pd6 = duty;
	else if (pin == 7) duty_pd7 = duty;
}

ISR(TIMER0_OVF_vect)
{
	pwm_count++;
	
	//Reiniciar el contador
	if (pwm_count >= 64)
	{
		pwm_count = 0;
	}
	
	//Contador con velocidad reducida
	static uint8_t divisor_ms = 0;
	divisor_ms++;
	if (divisor_ms >= 62) {
		ms_ticks++;
		divisor_ms = 0;
	}


	//Limite de 64 pasos para los motores
	
	if (pwm_count < (duty_pd4 >> 2)) PORTD |= (1 << PD4);
	else PORTD &= ~(1 << PD4);

	if (pwm_count < (duty_pd5 >> 2)) PORTD |= (1 << PD5);
	else PORTD &= ~(1 << PD5);

	if (pwm_count < (duty_pd6 >> 2)) PORTD |= (1 << PD6);
	else PORTD &= ~(1 << PD6);

	if (pwm_count < (duty_pd7 >> 2)) PORTD |= (1 << PD7);
	else PORTD &= ~(1 << PD7);
}
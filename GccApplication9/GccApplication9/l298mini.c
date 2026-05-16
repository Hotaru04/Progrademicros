/*
 * Libreria l298mini
 *
 * Created: 4/05/2026 15:59:09
 *  Author: Edwin Parada
 */ 
#include "L298Mini.h"
//Depende del pwm dc (manual)
#include "PWMdc.h" 

void L298_Init(void)
{
	//Iniciar pwm manual
	SoftPWM_Init(); 
}

void L298_MotorA(int16_t velocidad)
{
	// Motor A usa PD4 y PD5
	if (velocidad > 0) {
		// Adelante
		SoftPWM_SetDuty(4, (uint8_t)velocidad);
		SoftPWM_SetDuty(5, 0);
	}
	else if (velocidad < 0) {
		// Atras
		SoftPWM_SetDuty(4, 0);
		SoftPWM_SetDuty(5, (uint8_t)(-velocidad));
	}
	else {
		//Freno
		SoftPWM_SetDuty(4, 0);
		SoftPWM_SetDuty(5, 0);
	}
}

void L298_MotorB(int16_t velocidad)
{
	// Motor B usa PD6 y PD7
	if (velocidad > 0) {
		//Adelante
		SoftPWM_SetDuty(6, (uint8_t)velocidad);
		SoftPWM_SetDuty(7, 0);
	}
	else if (velocidad < 0) {
		//Atras
		SoftPWM_SetDuty(6, 0);
		SoftPWM_SetDuty(7, (uint8_t)(-velocidad));
	}
	else {
		//Freno
		SoftPWM_SetDuty(6, 0);
		SoftPWM_SetDuty(7, 0);
	}
}
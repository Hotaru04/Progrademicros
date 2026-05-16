/*
 * PWMdc.h
 *
 * Created: 4/05/2026 15:58:10
 *  Author: Edwin Parada
 */ 


#ifndef PWMDC_H_
#define PWMDC_H_

#include <avr/io.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
	#endif
	
	extern volatile uint32_t ms_ticks; // Variable global de tiempo

	void SoftPWM_Init(void);
	// Configura el Duty Cycle (0-255) en los pines PD4, PD5, PD6 o PD7
	void SoftPWM_SetDuty(uint8_t pin, uint8_t duty);

	#ifdef __cplusplus
}
#endif
#endif
/*
 * Servospwm.h
 *
 * Created: 4/05/2026 15:57:34
 *  Author: Edwin Parada
 */ 


#ifndef SERVOSPWM_H_
#define SERVOSPWM_H_

#include <avr/io.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
	#endif

	void Servos_Init(void);
	void Servo1_Set(uint8_t valor_adc); // PB1 
	void Servo2_Set(uint8_t valor_adc); // PB2
	void Servo3_Set(uint8_t valor_adc); // PB3
	void Servo4_Set(uint8_t valor_adc); // PD3

	#ifdef __cplusplus
}
#endif
#endif
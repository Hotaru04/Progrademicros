/*
 * ServoTimer1.h
 *
 * Created: 20/04/2026 00:56:18
 *  Author: MineS
 */ 
#ifndef SERVO_TIMER1_H_
#define SERVO_TIMER1_H_

#include <avr/io.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
	#endif

	// Prototipos
	void Servo_Init1(void);
	void Servo_SetPosition1(uint8_t valor_adc1); // Controla PB1 (Canal A)

	#ifdef __cplusplus
}
#endif

#endif /* SERVO_TIMER1_H_ */
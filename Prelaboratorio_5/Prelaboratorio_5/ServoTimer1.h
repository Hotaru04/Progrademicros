#ifndef SERVO_TIMER1_H_
#define SERVO_TIMER1_H_

#include <avr/io.h>
#include <stdint.h>

//Conservar nombres
#ifdef __cplusplus
extern "C" {
	#endif

	// Prototipos
	void Servo_Init(void);
	void Servo_SetPosition(uint8_t valor_adc);

	#ifdef __cplusplus
}
#endif

#endif /* SERVO_TIMER1_H_ */
/*
 * ServoTimer2.h
 *
 * Created: 20/04/2026 00:01:16
 *  Author: MineS
 */ 


#ifndef SERVOTIMER2_H_
#define SERVOTIMER2_H_

#include <avr/io.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
	#endif

	// Prototipos
	void Servo_Init2(void);
	void Servo_SetPosition2(uint8_t valor_adc2); // Controla PB3 (Canal B)

	#ifdef __cplusplus
}
#endif

#endif /* SERVOTIMER2_H_ */
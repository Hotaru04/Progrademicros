/*
 * l298mini.h
 *
 * Created: 4/05/2026 15:59:09
 *  Author: Edwin Parada
 */ 


#ifndef L298MINI_H_
#define L298MINI_H_

#include <stdint.h>

#ifdef __cplusplus

extern "C" {
	#endif

	void L298_Init(void);
	
	// Velocidad de -255 a 255
	void L298_MotorA(int16_t velocidad);
	void L298_MotorB(int16_t velocidad);

	#ifdef __cplusplus
}
#endif
#endif
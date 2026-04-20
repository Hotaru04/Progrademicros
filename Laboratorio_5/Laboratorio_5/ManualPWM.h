/*
 * ManualPWM.h
 *
 * Created: 20/04/2026 01:24:16
 *  Author: MineS
 */ 


#ifndef MANUALPWM_H_
#define MANUALPWM_H_

#include <avr/io.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
	#endif

	// Inicializa el Timer 0 y el pin del LED
	void ManualPWM_Init(void);

	// Actualiza el valor del Duty Cycle (0 a 255)
	void ManualPWM_Set(uint8_t valor_adc);

	#ifdef __cplusplus
}
#endif

#endif /* MANUALPWM_H_ */
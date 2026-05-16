/*
 * memoria1.h
 *
 * Created: 13/05/2026 18:18:33
 *  Author: Edwin Parada
 */ 

#ifndef MEMORIA1_H_
#define MEMORIA1_H_

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
	#endif

	// Direcciones físicas en la EEPROM (0 a 3)
	#define DIR_SERVO1 0x00
	#define DIR_SERVO2 0x01
	#define DIR_SERVO3 0x02
	#define DIR_SERVO4 0x03

	void EEPROM_GuardarPosiciones(uint8_t s1, uint8_t s2, uint8_t s3, uint8_t s4);
	void EEPROM_LeerPosiciones(uint8_t *s1, uint8_t *s2, uint8_t *s3, uint8_t *s4);

	#ifdef __cplusplus
}
#endif
#endif
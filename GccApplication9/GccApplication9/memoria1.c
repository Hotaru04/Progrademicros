/*
 * memoria1.c
 *
 * Created: 13/05/2026 18:18:47
 * Author: Edwin Parada
 * Libreria para Guardar posiciones
 */ 

#include "memoria1.h"
//Libreria de eprom
#include <avr/eeprom.h> 

void EEPROM_GuardarPosiciones(uint8_t s1, uint8_t s2, uint8_t s3, uint8_t s4)
{
	//Guardar las posiciones de todos los servomotores
	eeprom_update_byte((uint8_t*)DIR_SERVO1, s1);
	eeprom_update_byte((uint8_t*)DIR_SERVO2, s2);
	eeprom_update_byte((uint8_t*)DIR_SERVO3, s3);
	eeprom_update_byte((uint8_t*)DIR_SERVO4, s4);
}

void EEPROM_LeerPosiciones(uint8_t *s1, uint8_t *s2, uint8_t *s3, uint8_t *s4)
{
	//Leer las posiciones de los servomotores
	*s1 = eeprom_read_byte((const uint8_t*)DIR_SERVO1);
	*s2 = eeprom_read_byte((const uint8_t*)DIR_SERVO2);
	*s3 = eeprom_read_byte((const uint8_t*)DIR_SERVO3);
	*s4 = eeprom_read_byte((const uint8_t*)DIR_SERVO4);
}
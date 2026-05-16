/*
 * ControlSerial.h
 *
 * Created: 4/05/2026 16:11:01
 *  Author: Edwin Parada
 */ 


#ifndef CONTROLSERIAL_H_
#define CONTROLSERIAL_H_

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
	#endif

	// Variable global para saber el modo
	extern volatile uint8_t modo_control;

	void Serial_Init(void);
	void Serial_ProcesarComando(void);
	void writeChar(char caracter);
	void writeString(const char* string);

	#ifdef __cplusplus
}
#endif
#endif
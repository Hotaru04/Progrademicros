/*
 * ControlSerial.c
 *
 * Created: 4/05/2026 16:11:21
 * Author: Edwin Parada
 * Libreria para comunicacion Serial
 */ 

#include "ControlSerial.h"
#include "Servospwm.h" //Libreria de los servomotores
#include <avr/io.h>
#include <avr/interrupt.h>
#include <string.h>
#include <stdlib.h>

// Inicia con control manual
volatile uint8_t modo_control = 0;
 
// Buffer para comando de python
volatile char buffer_rx[16];
volatile uint8_t indice_rx = 0;
volatile uint8_t comando_listo = 0;

void Serial_Init(void)
{
	DDRD &= ~(1 << DDD0); // RX Entrada
	DDRD |= (1 << DDD1);  // TX Salida
	UCSR0A = 0;
	UCSR0B = (1 << RXCIE0) | (1 << RXEN0) | (1 << TXEN0);
	UCSR0C = (1 << UCSZ01) | (1 << UCSZ00);
	UBRR0 = 103; // 9600 Baudios
}

// Función llamada desde el main

//Cambio de modo Inalambrico y mover motores
void Serial_ProcesarComando(void)
{
	if (comando_listo)
	{
		// Cambio de modo, manual, memoria, serial
		
		//Modo 1 
		if (strncmp((char*)buffer_rx, "MODO:1", 6) == 0) {
			modo_control = 1;
		}
		
		//Modo2
		else if (strncmp((char*)buffer_rx, "MODO:2", 6) == 0) {
			modo_control = 2;
		}
		
		//Modo3
		else if (strncmp((char*)buffer_rx, "MODO:3", 6) == 0) {
			modo_control = 3;
		}
		
		// Modo remoto 3, leer desde phyton
		else if (modo_control == 3)
		{
			uint8_t valor = atoi((char*)&buffer_rx[3]);
			char buf_envio[4];
		
		// Servomotores, lee los servomotores y regresa el valor al que se movio
		
		//Motor 1
		if (strncmp((char*)buffer_rx, "S1:", 3) == 0) {
			Servo1_Set(valor);
			writeString("S1:"); itoa(valor, buf_envio, 10); writeString(buf_envio); writeString("\n");
		}
		//Motor2
		else if (strncmp((char*)buffer_rx, "S2:", 3) == 0) {
			Servo2_Set(valor); // ¡Corregido!
			writeString("S2:"); itoa(valor, buf_envio, 10); writeString(buf_envio); writeString("\n");
		}
		//Motor3
		else if (strncmp((char*)buffer_rx, "S3:", 3) == 0) {
			Servo3_Set(valor); // ¡Corregido!
			writeString("S3:"); itoa(valor, buf_envio, 10); writeString(buf_envio); writeString("\n");
		}
		//Motor4
		else if (strncmp((char*)buffer_rx, "S4:", 3) == 0) {
			Servo4_Set(valor); // ¡Corregido!
			writeString("S4:"); itoa(valor, buf_envio, 10); writeString(buf_envio); writeString("\n");
		}
		
		// Recepcion para motores DC, valor maximo 255.
		
		else if (strncmp((char*)buffer_rx, "C:", 2) == 0)
		{
			// Buscar la coma
			char *coma = strchr((char*)buffer_rx, ',');
			
			if (coma != NULL)
			{
				*coma = '\0'; // Cortar en dos partes el texto
				
				// Extraer los números del texto
				int16_t velA = atoi((char*)&buffer_rx[2]); // Leer la primera parte
				int16_t velB = atoi(coma + 1);             // Leer la segunda parte
				
				// Mover los 2 motores
				L298_MotorA(velA);
				L298_MotorB(velB);
				
				writeString("CHASIS:OK\n");
			}
		}
		}

		// Limpiar el buffer
		indice_rx = 0;
		buffer_rx[0] = '\0';
		comando_listo = 0;
	}
}

// Interrupcion, 
ISR(USART_RX_vect)
{
	char letra = UDR0;
	
	if (letra == '\n' || letra == '\r') {
		buffer_rx[indice_rx] = '\0'; // Cerrar la cadena
		comando_listo = 1;           // Levantar bandera
	}
	else if (indice_rx < 15 && comando_listo == 0) {
		buffer_rx[indice_rx] = letra;
		indice_rx++;
	}
}


//Enviar el caracter al monitor serial
void writeChar(char caracter)
{
	// Esperar a que el buffer se vacie
	// Esperar a que se envie el dato
	while(!(UCSR0A & (1 << UDRE0)));
	
	//Cargar nuevo caracter e iniciar la transmisión
	UDR0 = caracter;
}

// Enviar cadena de texto
void writeString(const char* string)
{

	//Recorrer por la cadena y terminar en enter.
	for (uint8_t i = 0; string[i] != '\0'; i++)
	{
		//writechar para enviar letra por letra
		writeChar(string[i]);
	}
}
/*
 * ServoTimer1.c
 * Descripción: Implementación de los registros para el control PWM.
 */

#include "ServoTimer1.h"

//Configurar hardware
void Servo_Init(void)
{
    // Configurar Pin del Servo (PB1) como salida
    DDRB |= (1 << PB1); 

    //Configurar Timer1 Fast PWM
    //Modo no invertido
    TCCR1A = (1 << COM1A1) | (1 << WGM11);
    
    // WGM13 = 1, WGM12 = 1. CS11 = 1 (Prescaler de 8)
    TCCR1B = (1 << WGM13) | (1 << WGM12) | (1 << CS11);
    
    // El Tope de los 50Hz (20ms)
    ICR1 = 39999; 
    
    // Posición inicial 0 
    OCR1A = 1000; 
}

void Servo_SetPosition(uint8_t valor_adc)
{
    // Mapeo con 32 bits
    uint16_t valor_pwm = 1000 + ((uint32_t)valor_adc * 4000) / 255;
    
    // Registro de comparacion del timer1
    OCR1A = valor_pwm;
}
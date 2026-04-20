/*
 * ManualPWM.c
 *
 * Created: 20/04/2026 01:23:00
 *  Author: MineS
 */ 

/*
 * SoftPWM.c
 * Descripción: Implementación del PWM manual con interrupción.
 */

#include "ManualPWM.h"
#include <avr/interrupt.h> // Necesario para la macro ISR()

// Variables globales volátiles (vitales cuando se usan en interrupciones)
volatile uint8_t contador_pwm = 0;
volatile uint8_t limite_pwm = 0; // Aquí guardamos la lectura del ADC

void ManualPWM_Init(void)
{
    // 1. Configurar Pin del LED (PD6) como salida
    DDRD |= (1 << PD6);
    PORTD &= ~(1 << PD6); // Inicia apagado

    // 2. Configurar Timer 0 (Modo Normal)
    TCCR0A = 0x00; // Modo normal, los pines por hardware están desconectados
    
    // 3. Encender el Timer sin Prescaler (CS00 = 1) para máxima velocidad
    TCCR0B = (1 << CS00);
    
    // 4. Habilitar la interrupción por desbordamiento (Overflow)
    TIMSK0 |= (1 << TOIE0);
}

void ManualPWM_Set(uint8_t valor_adc)
{
    // Actualizamos el límite al que debe llegar el contador para apagarse
    limite_pwm = valor_adc;
}

// ==========================================
// LA INTERRUPCIÓN (Se ejecuta 62,500 veces por segundo)
// ==========================================
ISR(TIMER0_OVF_vect)
{
    // Aumentamos el contador en cada interrupción
    // Como es uint8_t, al llegar a 255 regresará a 0 automáticamente
    contador_pwm++; 

    // Lógica especial de seguridad: si el ADC es 0, forzamos apagado total
    if (limite_pwm == 0) 
    {
        PORTD &= ~(1 << PD6); // Apagar LED
    }
    // REGLA 1: "El contador en cero deberá poner una salida en alto"
    else if (contador_pwm == 0) 
    {
        PORTD |= (1 << PD6);  // Encender LED
    }
    // REGLA 2: "Cuando llegue al valor seteado... poner en cero la salida"
    else if (contador_pwm == limite_pwm) 
    {
        PORTD &= ~(1 << PD6); // Apagar LED
    }
}
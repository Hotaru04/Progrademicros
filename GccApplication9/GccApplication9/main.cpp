/*
 * Proyecto Final:  Modo manual, EEPROM, UART
 * Author: Edwin Parada
 * Description: Control de Rovert curiositi con 4 servomotores y 2 motores dc
 * controlados por un l298 mini y pwm manual para 4 canales.
 */ 
#define F_CPU 16000000UL
#include <avr/io.h>
#include <avr/interrupt.h>

#include "Servospwm.h"
#include "ControlSerial.h"
#include "L298Mini.h"
#include "memoria1.h"
#include "PWMdc.h"

// Prototipos locales
void Configuracion_Pines(void);
uint8_t leerADC_8bits(uint8_t canal);
void Actualizar_LEDs(void);

// Potenciometros
uint8_t pot1, pot2, pot3, pot4, pot5, pot6;

// Variables de estados y botones

uint32_t t_boton_modo = 0;
uint8_t estado_boton_modo = 0;

uint32_t t_boton_guardar = 0;
uint8_t estado_boton_guardar = 0;

uint32_t t_led_parpadeo = 0;
uint8_t parpadeo_activo = 0;

int main(void)
{
	cli();
	
	//Configurar pines 
	Configuracion_Pines();
	//Inicializar servomotores
	Servos_Init();
	//Configurar l298
	L298_Init();
	//Configurar comunicacion serial
	Serial_Init();
	
	//Configurar adc, alineacion a la izquierda
	ADMUX = (1 << REFS0) | (1 << ADLAR);
	ADCSRA = (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0);
	
	sei();

	modo_control = 1;
	Actualizar_LEDs();

	while (1)
	{
		
		
		//MAQUINA DE ESTADOS PARA MODOS
		
		//Boton de modo
		uint8_t boton_modo_actual = !(PINC & (1 << PC0));
		
		// Cuenta para el antirrebote 
		if (estado_boton_modo == 0 && boton_modo_actual) {
			estado_boton_modo = 1;
			t_boton_modo = ms_ticks;
		}
		// Despues de 50 ticks se evalua nuevamente el boton
		else if (estado_boton_modo == 1 && (ms_ticks - t_boton_modo >= 50)) {
			if (boton_modo_actual) {
				
				//El boton seguia presionado aumenta modo
				modo_control++;
				
				//Limite del modo a 3
				if (modo_control > 3) modo_control = 1;
				Actualizar_LEDs();
				
				estado_boton_modo = 2; // Esperar que se suelte el boton
				} else {
				estado_boton_modo = 0; // Iniciar la cuenta de nuevo ya que fue ruido
			}
		}
		// No fue ruido, estado2 cambio  de modo
		
		else if (estado_boton_modo == 2 && !boton_modo_actual) {
			//Esperar a que se vuelva a presionar el boton
			estado_boton_modo = 0;
		}


		//MAQUINA DE ESSTADOS PARA GUARDAR EN EPROM
		
		//Antirrebote de boton y guardar grados del servomotor
		uint8_t boton_guardar_actual = !(PINC & (1 << PC1));
		
		if (estado_boton_guardar == 0 && boton_guardar_actual) {
			estado_boton_guardar = 1;
			t_boton_guardar = ms_ticks;
		}
		else if (estado_boton_guardar == 1 && (ms_ticks - t_boton_guardar >= 50)) {
			if (boton_guardar_actual) {
				EEPROM_GuardarPosiciones(pot1, pot2, pot3, pot4);
				
				// Parpadeo
				PORTD &= ~(1 << PD2); PORTB &= ~((1 << PB4) | (1 << PB5));
				parpadeo_activo = 1;
				t_led_parpadeo = ms_ticks;
				
				estado_boton_guardar = 2;
				} else {
				estado_boton_guardar = 0;
			}
		}
		else if (estado_boton_guardar == 2 && !boton_guardar_actual) {
			estado_boton_guardar = 0;
		}


		//Logica del parpadeo
		//Parpadeo mayor a >200 ms
		if (parpadeo_activo && (ms_ticks - t_led_parpadeo >= 200)) {
			// Termina el parpadeo
			parpadeo_activo = 0;
			//Volver a encender el led
			Actualizar_LEDs(); 
		}


		//ENVIO Y RECEPCION DE DATOS SERIALES
		Serial_ProcesarComando();
		if (!parpadeo_activo) Actualizar_LEDs();

		
		//MODO MANUAL
		
		//Control de  motores
		if (modo_control == 1) // MANUAL
		{
			pot1 = leerADC_8bits(2);
			pot2 = leerADC_8bits(3);
			pot3 = leerADC_8bits(4);
			pot4 = leerADC_8bits(5);
			pot5 = leerADC_8bits(6);
			pot6 = leerADC_8bits(7);
			
			Servo1_Set(pot1);
			Servo2_Set(pot2);
			Servo3_Set(pot3);
			Servo4_Set(pot4);
			
			
			//Control de motores DC cruzados
			static uint16_t pot5_filtrado = 127;
			static uint16_t pot6_filtrado = 127;

			//ADC(6) eje Y y ADC(7) eje X
			pot5_filtrado = (pot5_filtrado * 3 + leerADC_8bits(6)) / 4;
			pot6_filtrado = (pot6_filtrado * 3 + leerADC_8bits(7)) / 4;
			
			// Maoeo de 0 a 255 a -255 a 255
			int16_t eje_Y = ((int16_t)pot5_filtrado * 2) - 255;
			int16_t eje_X = ((int16_t)pot6_filtrado * 2) - 255;
			
			// Zona muerta en mitad del joystick
			if (eje_Y > -35 && eje_Y < 35) eje_Y = 0;
			if (eje_X > -35 && eje_X < 35) eje_X = 0;
			
			// Logica para simular el movimiento del rover
			//Llanta 1
			int16_t vel_motorA = eje_Y + eje_X;
			//Llanta 2
			int16_t vel_motorB = eje_Y - eje_X; 
			
			//Limite para valores del potencioemetro
			if (vel_motorA > 255) vel_motorA = 255;
			if (vel_motorA < -255) vel_motorA = -255;
			if (vel_motorB > 255) vel_motorB = 255;
			if (vel_motorB < -255) vel_motorB = -255;
			
			// Instrucciones al puente H,  2 canales cada motor
			L298_MotorA(vel_motorA);
			L298_MotorB(vel_motorB);
		}
		
		//MODO DE CONTROL EPROM
		else if (modo_control == 2)
		{
			uint8_t e1, e2, e3, e4;
			EEPROM_LeerPosiciones(&e1, &e2, &e3, &e4);
			
			Servo1_Set(e1); Servo2_Set(e2); Servo3_Set(e3); Servo4_Set(e4);
			L298_MotorA(0); L298_MotorB(0);
		}
		
		//MODO 3 A TRAVES DE CONTROL SERIAL
	}
}



//Configurar pines
void Configuracion_Pines(void)
{
    // Pines para leds de estados como salidas
    DDRD |= (1 << PD2);
    DDRB |= (1 << PB4) | (1 << PB5);
    
    //Botones como entradas
    DDRC &= ~((1 << PC0) | (1 << PC1));
	//Pull-ups activos 
    PORTC |= (1 << PC0) | (1 << PC1);
}

void Actualizar_LEDs(void)
{
    // Apagar todos
    PORTD &= ~(1 << PD2);
    PORTB &= ~((1 << PB4) | (1 << PB5));
    
    // Encender en orden
    if (modo_control == 1) PORTD |= (1 << PD2);       // LED Modo 1
    else if (modo_control == 2) PORTB |= (1 << PB4);  // LED Modo 2
    else if (modo_control == 3) PORTB |= (1 << PB5);  // LED Modo 3
}


//Lectura del adc
uint8_t leerADC_8bits(uint8_t canal)
{
    ADMUX = (ADMUX & 0xF0) | (canal & 0x0F);
    ADCSRA |= (1 << ADSC);
    while (ADCSRA & (1 << ADSC));
    return ADCH;
}
/*
 * EjemploPWM.cpp
 *
 * Created: 8/04/2026 16:54:49
 * Author : MineS
 */ 

#define F_CP 160000000
#include <avr/io.h>
#include <util/delay.h>

void initPWM0();
void updateDutycycle0A(uint8_t duty);
void updateDutycycle0B(uint8_t duty);

int main(void)
{
	uint8_t dutyCycle = 255;
    CLKPR = (1<<CLKPCE);
    CLKPR = (1<<CLKPS2);
	initPWM0();
    while (1) 
    {
		updateDutycycle0A(dutyCycle);
		updateDutycycle0B(dutyCycle);
		dutyCycle++;
		_delay_ms(1);	
    }
}

void initPWM0();
{
	//OCR0A = PB6, OCR0B = Pb5

	
	TCCR0A = 0;
	TCCR0B = 1;	
	//Configurar modo invertido
	TCCR0A |= (1<<COM0A1);
	TCCR0A |= (1<<COM0B1)|(1<<COM0B0);
	//Configurar mosdo fast pwm
	TCCR0A |= (1<<WGM01)|(1<<WGM00);
	TCCR0B |= (1<<CS01);
}

void updateDutycycle0A(uint8_t duty);
{
	OCR0A = duty;
	OCR0B = duty;
}
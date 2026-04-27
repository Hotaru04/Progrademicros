/*
 * Labortorio 6.cpp
 *
 * Created: 27/04/2026 08:54:28
 * Author : Edwin Parada
 * Description: Comunicacion serial, menu en hiperterminal,
 * y lector de potenciometro.
 */
 
//Librerias
#define F_CPU 16000000UL // Reloj a 16MHz
#include <avr/io.h>
#include <avr/interrupt.h>
#include <stdlib.h> //Para ascci y numeros a char


//Prototipos de funciones
void iniTuart(void);
void writeChar(char caracter);
void writeString(const char* string);
void mostrarMenu(void);
uint8_t leerADC_8bits(uint8_t canal);
void mostrarLEDs(char letra);

//Variables
volatile uint8_t estado = 0; //Estado para menu y escribir o leer
volatile char tecla = 0;
volatile uint8_t dato = 0;
volatile uint8_t valor_pot = 0;


//Main function

int main(void)
{
	cli();
	//Configuracion puerto
	DDRB = 0xFF; //Salida
	PORTB = 0x00; //Apagado
	
	DDRD |= (1 << DDD1) | (1 << DDD2) | (1 << DDD3);
	PORTD &= ~0x0C; // Apagado
	
	iniTuart();
	
	//Configuracion ADC
	ADMUX = (1 << REFS0)|(1 << ADLAR);
	ADCSRA = (1 << ADEN)|(1 << ADPS2)|(1 << ADPS1)|(1 << ADPS0);
	
	sei();
	
	//Mostrar Menu
	writeString("\r\n--- Encendiendo ---\r\n");
	mostrarMenu();
	
    /* Replace with your application code */
    while (1) 
    {
		if (dato == 1)
		{
			dato = 0;
			
			//Estado = 0
			if (estado == 0)
			{
				if (tecla == '1')
				{
					//Leer potenciometro
					
					uint8_t valor_pot = leerADC_8bits(6);
					
					//Conversion del numero a texto
					char buffer_texto[4];
					itoa(valor_pot, buffer_texto, 10);
					
					//Ver resultado
					writeString("\r\n >> Valor del potencioemetro:");
					writeString(buffer_texto);
					writeString("\r\n\n");
					
					//Regresar al menu
					mostrarMenu();
					
				}
			
				else if (tecla == '2')
				{
					//Escribir Digito
					
					writeString("\r\n>> Escribe un caracter para mostrar:");
					estado = 1;
				
				}
				else
				{
					writeString("\r\n>> Opcion invalida seleciona 1 o 2");
					mostrarMenu();
				}

			}
			else if (estado == 1)
			{
				//Estado 1 imprimir en los leds
				mostrarLEDs(tecla);
				//Caracter en puerto B y D
				writeString("\r\n>> Caracter");
				writeChar(tecla);
				writeString("enviado. \r\n\n");
				estado = 0;
				mostrarMenu();
			}
		}
    }
}

void mostrarMenu()
{
	writeString("1. Leer potenciometro\r\n");
	writeString("2. Enviar digitto\r\n");
	writeString("Elegir una opcion 1 o 2");
}


uint8_t leerADC_8bits(uint8_t canal)
{
	ADMUX = (ADMUX & 0xF0)|(canal & 0x0F);
	ADCSRA |= (1 << ADSC);
	while (ADCSRA & (1 << ADSC));
	return ADCH;
}

void iniTuart(void)
{
	DDRD &= ~(1 << DDD0);
	DDRD |= (1 << DDD1);
	
	UCSR0A = 0;
	UCSR0B = (1 << RXCIE0) | (1 << RXEN0) | (1 << TXEN0);
	UCSR0C = (1 << UCSZ01) | (1 << UCSZ00);
	UBRR0 = 103; // 9600 Baudios	
}

void writeChar(char caracter)
{
	while(!(UCSR0A &(1 << UDRE0)));
	UDR0 = caracter;
}

void writeString(const char* string)
{
	for (uint8_t i = 0; string[i] != '\0'; i++)
	{
		writeChar(string[i]);
	}
}

//Mostrar en Puerto B y D
void mostrarLEDs(char letra)
{
	// 6 Bits al puerto B
	// 0x3F  0011 1111. 0xC0
	PORTB = (PORTB & 0xC0) | (letra & 0x3F);
	// 2 Bits a PD2 y PD3
	
	// 0x0C 1100 >> 4 espacios 0000 11000
	PORTD = (PORTD & ~0x0C) | ((letra >> 4) & 0x0C);
}

// ISR Serial

ISR(USART_RX_vect)
{
	tecla = UDR0;
	dato = 1;
}
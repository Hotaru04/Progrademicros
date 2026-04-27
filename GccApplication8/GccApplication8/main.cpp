/*
 * Serial.c
 *
 * Descripción: Prelaboratorio 6
 */ 

//2#define F_CPU 16000000UL // Reloj a 16MHz

#include <avr/io.h>
#include <avr/interrupt.h>

//Prototipos
void initUART(void);
void writeChar(char caracter);
void writeString(const char* string);
//Potenciometro
volatile uint8_t valor_potenciometro = 0; 

uint8_t leerADC_8bits(uint8_t canal);

//Main
int main(void)
{
    cli();
    
    // Configurar el Puerto B como salida
    DDRB = 0xFF;  
    PORTB = 0x00; // Iniciar con los LEDs apagados
    
    // Inicializar el módulo de comunicación Serial
    initUART();
	
	// Configuracion alineacion a la izquierda 8 bits mas significativos
	ADMUX = (1 << REFS0) | (1 << ADLAR);
	ADCSRA = (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0);
    
    sei(); 
    writeChar('H');
    writeChar('o');
    writeChar('l');
    writeChar('a');
    writeChar('.');
    
    // Linea
    writeString("Hola mundo\r\n");
    

    while (1)
    {
		valor_potenciometro = leerADC_8bits(6); 
    }
}

//Lectura de ADC
uint8_t leerADC_8bits(uint8_t canal)
{
	ADMUX = (ADMUX & 0xF0) | (canal & 0x0F);
	ADCSRA |= (1 << ADSC);
	while (ADCSRA & (1 << ADSC));
	return ADCH;
}

void initUART(void)
{
    // Rx tx entrada y salida
    DDRD &= ~(1 << DDD0); // Limpiar bit 0 
    DDRD |= (1 << DDD1);  // Setear bit 1 
        
    UCSR0A = 0;
    
    // Habilitando interrupciones de RX, y encendiendo modulos RX y TX
    UCSR0B = (1 << RXCIE0) | (1 << RXEN0) | (1 << TXEN0);
    
    // Asíncrono, paridad deshabilitada, 1 stop bit y 8 data bits
    UCSR0C = (1 << UCSZ01) | (1 << UCSZ00);
    
    // Setear UBRR0 = 103 9600 baudios
    UBRR0 = 103;
}

void writeChar(char valor_potenciometro)
{
   
    while(!(UCSR0A & (1 << UDRE0)));
    
    UDR0 = valor_potenciometro;
}

void writeString(const char* string)
{
    
    for (uint8_t i = 0; string[i] != '\0'; i++)
    {
        writeChar(string[i]);
    }
}




ISR(USART_RX_vect)
{
    // Leer digito elegido
    char bufferRX = UDR0;
    
    // Valor asci
    PORTB = bufferRX;
    
    writeChar(bufferRX);
}
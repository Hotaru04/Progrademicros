/*
 * Serial.c
 *
 * Descripción: Prelaboratorio 6
 */ 

#define F_CPU 16000000UL // Reloj a 16MHz

#include <avr/io.h>
#include <avr/interrupt.h>

//Prototipos
void initUART(void);
void writeChar(char caracter);
void writeString(const char* string);

//Main
int main(void)
{
    cli();
    
	//Configurar el puerto D como salida
	DDRD = 0xFF;
	PORTD = 0xFF;
	
    // Configurar el Puerto B como salida
    DDRB = 0xFF;  
    PORTB = 0x00; // Iniciar con los LEDs apagados
    
    // Inicializar el módulo de comunicación Serial
    initUART();
    
    sei(); 
    writeChar('H');
    writeChar('o');
    writeChar('l');
    writeChar('a');
    writeChar('.');
    
    // Linea
    writeString("Hola :3");
    

    while (1)
    {
    }
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
    
    // Setear UBRR0 = 103 = 9600 baudios
    UBRR0 = 103;
}

void writeChar(char caracter)
{
   
    while(!(UCSR0A & (1 << UDRE0)));
    
    UDR0 = caracter;
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
	PORTB = (PORTB & 0xC0) | (bufferRX & 0x3F);
	PORTD = (PORTD & ~0x0C) | ((bufferRX >> 4) & 0x0C);
	
    writeChar(bufferRX);
}
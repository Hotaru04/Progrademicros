import sys
import time
import serial
from Adafruit_IO import MQTTClient

#Configuracion para conectar a adafruit

# Feeds que leera phyton de Adafruit
FEEDS = [
    #Feed de modo
    'modo-control',
    #Feed de control de servomotores
    'servo-1', 'servo-2', 'servo-3', 'servo-4',
    #Feed de control de motores DC
    'motores' 
]

# Feed para la retroalimentacion en la consola
FEED_FEEDBACK = 'consola-feedback' 

#Iniciar el puerto serial para la comunicacion
try:
    #Mensaje de apertura
    print(f"Abriendo puerto {PUERTO_COM}...")
    #Configuracion de puerto serial y BaudRate
    arduino = serial.Serial(PUERTO_COM, 9600, timeout=0.1)
    # Pausa para reiniciar el arudino
    time.sleep(2)
    #Confirmacion de inicializacion de la comunicacion serial
    print("Comunicación serial establecida.\n")
    #Si no se puede abrir el puerto
except Exception as e:
    print(f"Error fatal: No se pudo abrir el puerto serial. {e}")
    sys.exit(1)

# Cnfirmacion de coneccion a Adafruit IO
def connected(client):
    print("¡Conectado a Adafruit IO!")
    for feed in FEEDS:
        client.subscribe(feed)
    client.publish(FEED_FEEDBACK, "Sistema en linea y escuchando...")

def disconnected(client):
    print("Desconectado de Adafruit IO.")
    sys.exit(1)

def message(client, feed_id, payload):
    # Limpiar el dato recibido de espacios ocultos y pasarlo a mayúsculas
    payload_str = str(payload).strip().upper()
    print(f"[Nube] -> Feed '{feed_id}' recibió: {payload_str}")
    

# Recepcion e interpetacion de comandos de Adafruit
    # Control de Modos
    if feed_id == 'modo-control':
        arduino.write((f"MODO:{payload_str}\n").encode('utf-8'))
        
    # Mapeo de 180 grados y control de los servomotores
    elif 'servo' in feed_id:
        valor_int = int(payload_str)
        valor_arduino = int((valor_int * 255) / 180)
        
        # Limitar valores para evitar errores
        if valor_arduino > 255: valor_arduino = 255
        if valor_arduino < 0: valor_arduino = 0
        
        # Enviar los comandos al microcontrolador con el formato "S1:127"
        if feed_id == 'servo-1': arduino.write((f"S1:{valor_arduino}\n").encode('utf-8'))
        elif feed_id == 'servo-2': arduino.write((f"S2:{valor_arduino}\n").encode('utf-8'))
        elif feed_id == 'servo-3': arduino.write((f"S3:{valor_arduino}\n").encode('utf-8'))
        elif feed_id == 'servo-4': arduino.write((f"S4:{valor_arduino}\n").encode('utf-8'))

    #Control de motores DC con el pad (Sin pwm para un control más directo)
    elif feed_id == 'motores':
        vel_a = 0
        vel_b = 0
        
        # Mapeo direccional con los valores del pad
        if payload_str == '5':        # Arriba
            vel_a = 255
            vel_b = 255
        elif payload_str == '13':     # Abajo
            vel_a = -255
            vel_b = -255
        elif payload_str == '8':      # Izquierda
            vel_a = -255
            vel_b = 255
        elif payload_str == '10':     # Derecha
            vel_a = 255
            vel_b = -255
        elif payload_str == '9':      # Botón Central (STOP)
            vel_a = 0
            vel_b = 0
            
  
            
        # Enviar un solo comando unificado al arduino
        cmd_chasis = f"C:{vel_a},{vel_b}\n"
        
        arduino.write(cmd_chasis.encode('utf-8'))
        print(f"[UART TX] -> Enviado al carro unificado: {cmd_chasis.strip()}")


#Establcer conexion con Adafruit IO
client = MQTTClient(ADAFRUIT_IO_USERNAME, ADAFRUIT_IO_KEY)
client.on_connect = connected
client.on_disconnect = disconnected
client.on_message = message

print("Iniciando Gateway MQTT-Serial...")
client.connect()
client.loop_background() # Coneccion en segundo plano


#Bucle principal de comunicacion serial y retroalimentacion

try:
    while True:
        # Si el Arduino envia datos
        if arduino.in_waiting > 0:
            # Leer la linea y adaptarla al formato de texto 
            respuesta_hardware = arduino.readline().decode('utf-8').strip()
            
            if respuesta_hardware:
                print(f"Hardware RX <- {respuesta_hardware}")
                
                # Revisar si es una confirmación de posición con el formato "S1:127"
                if ":" in respuesta_hardware:
                    prefijo, valor_raw = respuesta_hardware.split(":")
                    
                    try:
                        # Retroalimentacion de los servomotores
                        if prefijo in ["S1", "S2", "S3", "S4"]:
                            valor_int = int(valor_raw)
                            grados = int((valor_int * 180) / 255) # Conversión inversa
                            
                            # Actualizar los Gauges correspondientes
                            if prefijo == "S1": client.publish('servo-1-fb', grados)
                            elif prefijo == "S2": client.publish('servo-2-fb', grados)
                            elif prefijo == "S3": client.publish('servo-3-fb', grados)
                            elif prefijo == "S4": client.publish('servo-4-fb', grados)
                            
                        # Retroalimentacion de los motores DC en la consola de phyton
                        elif prefijo in ["M_A", "M_B"]: 
                            client.publish('consola-feedback', f"Motor {prefijo} OK")
                            
                    except ValueError:
                        # Si hubo un error convirtiendo números se muestran en la consola
                        client.publish('consola-feedback', respuesta_hardware)
                else:
                    # Si es texto normal ("S1 OK", etc.), va a la consola de texto
                    client.publish('consola-feedback', respuesta_hardware)
                    
        # Pequeño descanso para no consumir el 100% del procesador de la PC
        time.sleep(0.05)
        
except KeyboardInterrupt:
    print("\nDeteniendo sistema de forma segura...")
    arduino.close()
    sys.exit(0)
# Telemetría y Control Bluetooth

Este es el código principal para el ESP32. Básicamente, se encarga de leer los datos de varios sensores (temperatura, humedad, luz, aceleración/impactos y GPS), empaquetar todo en un JSON y mandarlo por Bluetooth Classic. Además, se queda escuchando por si la app le manda el comando para mover un servomotor y abrir la caja.

---

## Configuración previa (Placa ESP32)

Si es tu primera vez usando un ESP32 en el Arduino IDE, acuérdate de agregar la URL de Espressif en las preferencias antes de compilar:
1. Ve a **Archivo > Preferencias**.
2. Pega esto en el Gestor de URLs Adicionales: `https://dl.espressif.com/dl/package_esp32_index.json`
3. Ve a **Herramientas > Placa > Gestor de tarjetas**, busca **esp32** y dale a instalar.

---

## Librerías que tienes que instalar

Para evitar los típicos errores de compilación porque falta una dependencia, ve al Gestor de Librerías del Arduino IDE  y busca estas librerías exactas:

* **Para el sensor sumergible (DS18B20):** 
  * `OneWire` (la de Paul Stoffregen).
  * `DallasTemperature` (la de Miles Burton).
* **Para la temperatura y humedad ambiente:** 
  * `DHT sensor library` (de Adafruit)
* **Para el sensor de luz:** 
  * `BH1750` (de Christopher Laws).
* **Para los impactos (MPU6050):** 
  * `Adafruit MPU6050` (de Adafruit).
* **Para leer el GPS:** 
  * `TinyGPSPlus` (de Mikal Hart)
* **Para el Servomotor:** 
  * `ESP32Servo` (de Kevin Harrington)

---

## Pinout

Así es como está mapeado el hardware en el código:

* **Pines I2C (Compartido por el MPU6050 y el BH1750):** SDA en el pin `21` y SCL en el `22`.
* **Sensor DS18B20:** Pin `4`. (No olvides ponerle la resistencia pull-up de 4.7kΩ).
* **Sensor DHT22:** Pin `5`.
* **Módulo GPS:** El TX del GPS va al pin `16` (RXD2) y el RX del GPS al `17` (TXD2). 
* **Servomotor:** Pin `18`.

---

## ¿Cómo se prueba esto?

1. Sube el código al ESP32.
2. Abre el Bluetooth en tu celular o compu, busca el dispositivo **`ESP32_Telemetria_Bryan`** y conéctate.
3. Apenas se conecte, el ESP32 va a empezar a mandar un JSON cada 3 segundos por el puerto serial del Bluetooth. Se verá más o menos así:
```json
   {
     "temperatura_interna": 25.50,
     "temperatura_ambiente": 26.10,
     "humedad": 55.20,
     "lux": 150.00,
     "fuerza_g_impacto": 1.02,
     "latitud_actual": 4.609710,
     "longitud_actual": -74.081750,
     "altitud": 2600.00
   }

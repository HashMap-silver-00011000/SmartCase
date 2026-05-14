// #include <Wire.h>
// #include <Adafruit_MPU6050.h>
// #include <Adafruit_Sensor.h>
// #include <BH1750.h>
// #include <DHT.h>
// #include <OneWire.h>
// #include <DallasTemperature.h>
// #include <TinyGPS++.h>
// #include "BluetoothSerial.h"

// --- CONFIGURACIÓN DE PINES ---
const int pinDS18B20 = 4;
const int pinDHT = 5;
const int RXD2 = 16; 
const int TXD2 = 17; 

// --- INSTANCIAS ---
BluetoothSerial SerialBT;
OneWire oneWire(pinDS18B20);
DallasTemperature ds18b20(&oneWire);
DHT dht(pinDHT, DHT22);
BH1750 lightMeter;
Adafruit_MPU6050 mpu;
TinyGPSPlus gps;
HardwareSerial SerialGPS(2);

// --- VARIABLES DE CONTROL ---
unsigned long tiempoAnterior = 0;
const long intervaloReporte = 3000; // Enviar cada 3 segundos

void setup() {
  // Inicializamos el Serial tradicional solo por si necesitas debuggear por cable,
  // pero los datos finales solo saldrán por Bluetooth.
  Serial.begin(115200);
  SerialGPS.begin(9600, SERIAL_8N1, RXD2, TXD2);
  Wire.begin(21, 22);

  // Iniciar Bluetooth
  SerialBT.begin("ESP32_Telemetria_Bryan"); 

  ds18b20.begin();
  dht.begin();
  lightMeter.begin(BH1750::CONTINUOUS_HIGH_RES_MODE);
  
  if (mpu.begin()) {
    mpu.setAccelerometerRange(MPU6050_RANGE_16_G);
    mpu.setFilterBandwidth(MPU6050_BAND_21_HZ);
  }
}

void loop() {
  // 1. LECTURA GPS (Background continuo)
  while (SerialGPS.available() > 0) {
    gps.encode(SerialGPS.read());
  }

  // 2. REPORTE PERIÓDICO (Cada 3 segundos)
  unsigned long tiempoActual = millis();
  if (tiempoActual - tiempoAnterior >= intervaloReporte) {
    tiempoAnterior = tiempoActual;
    
    // Leemos la aceleración justo en el momento de enviar el reporte
    sensors_event_t a, g, tempMPU;
    mpu.getEvent(&a, &g, &tempMPU);
    float accTotal = sqrt(pow(a.acceleration.x, 2) + 
                          pow(a.acceleration.y, 2) + 
                          pow(a.acceleration.z, 2));

    // Llamamos a la función de empaquetado
    enviarJSON(accTotal);
  }
}

// Función para empaquetar y enviar los datos SOLO por Bluetooth
void enviarJSON(float vibracion) {
  ds18b20.requestTemperatures();
  float tAgua = ds18b20.getTempCByIndex(0);
  float h = dht.readHumidity();
  float tAmb = dht.readTemperature();
  float lux = lightMeter.readLightLevel();

  // Construcción manual de la cadena JSON (con las llaves ajustadas para Go)
  String json = "{";
  
  // Reemplaza esto por el ID UUID real del bus si tu frontend no lo añade
  json += "\"id_bus\":\"123e4567-e89b-12d3-a456-426614174000\",";
  
  // Datos de los sensores
  json += "\"t_int\":" + String(tAgua, 2) + ",";
  json += "\"t_amb\":" + String(isnan(tAmb) ? 0 : tAmb, 2) + ",";
  json += "\"hum\":" + String(isnan(h) ? 0 : h, 2) + ",";
  json += "\"lux\":" + String(lux, 1) + ",";
  json += "\"acc\":" + String(vibracion, 2) + ","; // Mandamos la vibración cruda
  
  // Datos GPS
  if (gps.location.isValid()) {
    json += "\"lat\":" + String(gps.location.lat(), 6) + ",";
    json += "\"long\":" + String(gps.location.lng(), 6) + ",";
    json += "\"alt\":" + String(gps.altitude.meters(), 1);
  } else {
    // Si no hay señal de satélite, enviamos ceros
    json += "\"lat\":0.0,\"long\":0.0,\"alt\":0.0";
  }
  
  json += "}";

  // Enviar ÚNICAMENTE por Bluetooth hacia la App Móvil (Frontend)
  SerialBT.println(json); 
}
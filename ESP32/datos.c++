#include <Wire.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include <BH1750.h>
#include <DHT.h>
#include <OneWire.h>
#include <DallasTemperature.h>
#include <TinyGPS++.h>
#include "BluetoothSerial.h"
#include <ESP32Servo.h>   

// --- CONFIGURACIÓN DE PINES ---
const int pinDS18B20  = 4;
const int pinDHT      = 5;
const int RXD2        = 16;
const int TXD2        = 17;
const int PIN_SERVO   = 18;   

// --- GRADOS DEL SERVO ---

const int GRADOS_CERRADO  =   0;   // posición de reposo
const int GRADOS_ABIERTO  = 180;   // posición al verificar entrega

// --- INSTANCIAS ---
BluetoothSerial SerialBT;
OneWire oneWire(pinDS18B20);
DallasTemperature ds18b20(&oneWire);
DHT dht(pinDHT, DHT22);
BH1750 lightMeter;
Adafruit_MPU6050 mpu;
TinyGPSPlus gps;
HardwareSerial SerialGPS(2);
Servo servo;   // ← NUEVO

// --- VARIABLES DE CONTROL ---
unsigned long tiempoAnterior = 0;
const long intervaloReporte  = 3000;

// ── NUEVO: abre el servo y lo deja abierto ────────────────────────────────────
void abrirCaja() {
  Serial.println(">>> COMANDO RECIBIDO: ABRIR_CAJA");  // debug por cable
  SerialBT.println("{\"evento\":\"ejecutando_servo\"}");
  
  servo.write(GRADOS_ABIERTO);
  delay(1000);
  
  Serial.println(">>> SERVO MOVIDO A: " + String(GRADOS_ABIERTO));
  SerialBT.println("{\"evento\":\"caja_abierta\"}");
}

void setup() {
  Serial.begin(115200);
  SerialGPS.begin(9600, SERIAL_8N1, RXD2, TXD2);
  Wire.begin(21, 22);

  SerialBT.begin("ESP32_Telemetria_Bryan");

  ds18b20.begin();
  dht.begin();
  lightMeter.begin(BH1750::CONTINUOUS_HIGH_RES_MODE);

  if (mpu.begin()) {
    mpu.setAccelerometerRange(MPU6050_RANGE_16_G);
    mpu.setFilterBandwidth(MPU6050_BAND_21_HZ);
  }

  // ── NUEVO: inicializar servo en posición cerrada ──────────────────────────
  servo.attach(PIN_SERVO);
  servo.write(GRADOS_CERRADO);
  delay(500);
}

void loop() {
  // 1. GPS
  while (SerialGPS.available() > 0) {
    gps.encode(SerialGPS.read());
  }

  // 2. NUEVO: leer comandos entrantes desde la app Flutter
if (SerialBT.available()) {
  String cmd = SerialBT.readStringUntil('\n');
  cmd.trim();
  Serial.println(">>> CMD RECIBIDO: [" + cmd + "]");  // ← debug
  if (cmd == "ABRIR_CAJA") {
    abrirCaja();
  }
}

  // 3. Reporte periódico
  unsigned long tiempoActual = millis();
  if (tiempoActual - tiempoAnterior >= intervaloReporte) {
    tiempoAnterior = tiempoActual;

    sensors_event_t a, g, tempMPU;
    mpu.getEvent(&a, &g, &tempMPU);
    float accTotal = sqrt(pow(a.acceleration.x, 2) +
                          pow(a.acceleration.y, 2) +
                          pow(a.acceleration.z, 2));
    enviarJSON(accTotal);
  }
}

void enviarJSON(float vibracion) {
  ds18b20.requestTemperatures();
  float tAgua = ds18b20.getTempCByIndex(0);
  float h     = dht.readHumidity();
  float tAmb  = dht.readTemperature();
  float lux   = lightMeter.readLightLevel();

  String json = "{";
  json += "\"temperatura_interna\":"  + String(tAgua, 2) + ",";
  json += "\"temperatura_ambiente\":" + String(isnan(tAmb) ? 0 : tAmb, 2) + ",";
  json += "\"humedad\":"              + String(isnan(h) ? 0 : h, 2) + ",";
  json += "\"lux\":"                  + String(lux, 2) + ",";
  json += "\"fuerza_g_impacto\":"     + String(vibracion, 2) + ",";

  if (gps.location.isValid()) {
    json += "\"latitud_actual\":"  + String(gps.location.lat(), 6) + ",";
    json += "\"longitud_actual\":" + String(gps.location.lng(), 6) + ",";
    json += "\"altitud\":"         + String(gps.altitude.meters(), 2);
  } else {
    json += "\"latitud_actual\":0.0,";
    json += "\"longitud_actual\":0.0,";
    json += "\"altitud\":0.0";
  }

  json += "}";
  SerialBT.println(json);
}

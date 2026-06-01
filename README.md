# SmartCase

A nivel mundial, la integridad de las muestras biológicas y los órganos durante su transporte
representa uno de los mayores desafíos en la fase preanalítica de los laboratorios clínicos. La
Organización Mundial de la Salud (OMS) advierte constantemente sobre los riesgos biológicos y
diagnósticos de las fallas en la cadena de frío, estableciendo protocolos estrictos para el transporte de
sustancias infecciosas y biológicas [1](https://www.who.int/publications/i/item/9789240019720). Las variaciones térmicas y los traumatismos físicos durante el
tránsito global son responsables de un alto porcentaje de muestras rechazadas, lo que retrasa
diagnósticos críticos e incrementa los costos operativos de los sistemas de salud.
A nivel nacional, en Colombia, el Instituto Nacional de Salud (INS) exige el cumplimiento riguroso
de directrices para la conservación y envío de muestras, subrayando que la topografía y los retos
logísticos del país facilitan las rupturas en la cadena de frío y los tiempos prolongados de traslado [2](https://www.ins.gov.co/BibliotecaDigital/Manual-toma-envio-muestras-ins.pdf).
A pesar de las normativas, muchos centros de salud en el territorio nacional aún dependen de neveras
pasivas (refrigerantes en gel) sin monitoreo activo, lo que crea "puntos ciegos" de información durante
el trayecto.
Aterrizando esta problemática a nivel local, en la ciudad de Bucaramanga, el tránsito de componentes
sanguíneos y muestras sensibles (como los sueros destinados a pruebas de serología como el VDRL o
cultivos microbiológicos) entre las sedes del Instituto Cardiovascular de Colombia enfrenta riesgos
logísticos cotidianos. La topografía de la ciudad, el tráfico vehicular y las altas temperaturas
ambientales promedio (frecuentemente superiores a 27°C) amenazan la estabilidad térmica de las
muestras, que requieren mantenerse estrictamente por debajo de los 8°C. Además, las vibraciones
constantes del transporte terrestre pueden provocar la hemólisis de las muestras sanguíneas, alterando
gravemente la correlación clínica en el laboratorio, mientras que la falta de seguimiento satelital
impide garantizar la cadena de custodia en tiempo real.

El desarrollo de este proyecto es una alternativa fundamental para modernizar los procesos logísticos
intrahospitalarios. Incorporar el Internet de las Cosas (IoT) en el ámbito de la salud permite
evolucionar de un modelo de "reacción" (rechazar la muestra hemolizada o caliente al llegar al
laboratorio) a un modelo de "prevención" en tiempo real [3](https://ui.adsabs.harvard.edu/abs/2020isdf.conf...48M/abstract). Utilizar un microcontrolador de bajo
costo y alta capacidad como el ESP32, combinado con sensores de precisión y actuadores,
proporciona una solución escalable y económicamente viable en comparación con los costosos
equipos comerciales de transporte especializado. Este sistema garantiza la calidad preanalítica,
protege la validez de las pruebas diagnósticas y asegura la confiabilidad institucional ante auditorías
de salud pública, eliminando los errores humanos en la trazabilidad de los especímenes críticos.

---

## Objetivos
### General
Desarrollar un prototipo de "Smart-Case" basado en arquitectura IoT para el monitoreo en
tiempo real, control térmico y aseguramiento de la cadena de custodia en el transporte
logístico de muestras biológicas crítica

### Especificos
- Diseñar el sistema de control térmico automatizado integrando un sensor de temperatura y un
módulo de enfriamiento Peltier gestionado por un microcontrolador ESP32.
- Implementar un módulo de geolocalización satelital para establecer geovallas logísticas y
restringir la apertura de la nevera únicamente en las coordenadas autorizadas de destino.
- Programar un sistema de detección de impactos y vibraciones mediante acelerometría para
alertar de manera inmediata sobre posibles compromisos en la integridad física de las
muestras transportadas.

---

# Ejecuta el BACKEND en tu maquína

## Requisitos

- Go en tu [maquina](https://go.dev/doc/install)
- Base de datos [PostgreeSQL](https://www.postgresql.org/download/)
- Copiar la estructura del archivo .env-example, luego de forma local crear el archivo .env

## Pasos para la ejecución

### INSTALACIÓN
1. Clona el repositorio
   ```bash
   git clone https://github.com/HashMap-silver-00011000/SmartCase
    
2. Navegar al directorio del proyecto
   ```bash
   cd SmartCase

### Ajustes en Main para ejecución y pruebas locales
- Se requiere hacer unos ajustes en las funciones llamadas en el main, ya que se cuenta con dos funciones para la carga de archivos, las cuales son; LoadConfig (para variables de entorno locales) y LoadConfigNeon (para las variables de entorno configuradas en Render)
  ```go
  func main(){

	cfg := config.LoadConfig()

   conexionDB , err : database.ConectarDB(cfg)
  	if err != nil {
		log.Fatalf("Error fatal: No se pudo conectar a PostgreSQL: %v", err)
	}

	defer conexionDB.Close() // Asegura que la base de datos se cierre al apagar el servidor

	telemetriaRepo := repository.NewTelemetriaRepository(conexionDB)
	hub := websockets.NewHub(telemetriaRepo)

	go hub.Run()

	// 3. Configurar el Enrutador
	router := routes.ConfigurarRutas(conexionDB,hub)

	// 4. Encender el servidor
	log.Println("Servidor operando en el puerto 8080...")
	if err := router.Run(":8080"); err != nil {
		log.Fatalf("Error al arrancar el servidor: %v", err)
	}
  }

 Realizar los ajustes en el main con la finalidad de ejecutar el proyecto de forma local es una alternativa al uso de Render, por defecto el proyecto ya está configurado para que trabaje en Render

---

# Ejecución del FRONTEND

## Requisitos

- [Android SDK](https://developer.android.com/studio?gclsrc=aw.ds&gad_source=1&gad_campaignid=21831783795&gclid=Cj0KCQjw2_TQBhCnARIsAF3-XhzFfDFPppg3FoI3jIKe9y9YIVsxszqc51TQltD84YKb1wwVc8y4RVgaAmbSEALw_wcB&hl=es-419)
- [Flutter](https://docs.flutter.dev/install)


Para ejecutar el frontend de **metro_gps** localmente y permitir que la aplicación móvil se comunique correctamente con el servidor backend de desarrollo, se deben seguir los siguientes pasos:

 1. Ubicarse en el directorio raíz
Estar posicionado dentro de la carpeta principal del proyecto:
```bash
cd metro_gps

```
2.Habilitar el puertoon ADB (Solo para Android)
```bash
adb reverse tcp:8080 tcp:8080
```

3.Ejecutar la aplicación en Flutter
```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8080
```



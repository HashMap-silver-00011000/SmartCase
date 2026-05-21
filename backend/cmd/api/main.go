package main

import (
	"log"
	

	"backend/config"
	"backend/internal/repository"
	"backend/internal/server/routes"
	"backend/internal/websockets"
	"backend/pkg/database"
)

func main(){
	
	cfg := config.LoadConfig()

	conexionDB, err := database.ConectarDB(cfg)
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
package main

import (
	"log"
	

	"backend/config"
	"backend/pkg/database"
	"backend/internal/server/routes"
	"backend/internal/websockets"
)

func main(){
	
	cfg := config.LoadConfig()

	conexionDB, err := database.ConectarDB(cfg)
	if err != nil {
		log.Fatalf("Error fatal: No se pudo conectar a PostgreSQL: %v", err)
	}
	defer conexionDB.Close() // Asegura que la base de datos se cierre al apagar el servidor

	hub := websockets.NewHub()

	go hub.Run()

	// 3. Configurar el Enrutador
	router := routes.ConfigurarRutas(conexionDB,hub)

	// 4. Encender el servidor
	log.Println("Servidor operando en el puerto 8080...")
	if err := router.Run(":8080"); err != nil {
		log.Fatalf("Error al arrancar el servidor: %v", err)
	}

}
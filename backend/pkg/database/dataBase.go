package database

import (
	"github.com/jmoiron/sqlx"
	"log"
	"fmt"

	"backend/config"
	_ "github.com/lib/pq"
)

func ConectarDB(cfg *config.Config) (*sqlx.DB , error){

	//dsn, cadena de conexion que el drver parsea para obtener las variables de entorno
	dsn := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode = disable",
						cfg.DBHost , cfg.DBPort , cfg.DBUser , cfg.DBPassword, cfg.DBName)
	
	//Abrir la conexión
	db, err := sqlx.Connect("postgres", dsn)

	if err != nil {
		return nil, fmt.Errorf("error al abrir la base de datos: %v", err)
	}
	log.Print(db.Stats())
	// verificar conexión
	err = db.Ping()
	if err != nil {
		return nil, fmt.Errorf("error al hacer ping a la base de datos: %v", err)
	}

	//log.Println("Conexión establecida")
	return db, nil

}
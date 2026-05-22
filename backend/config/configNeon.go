package config

import (
	"fmt"
	"os"

	"github.com/jmoiron/sqlx"
	"github.com/joho/godotenv"
	

	_ "github.com/jackc/pgx/v5/stdlib" 
)


func LoadConfigNeon() (*sqlx.DB, error) {
	

	err := godotenv.Load("../../.env") 
	if err != nil {
		return nil, fmt.Errorf("error cargando archivo .env: %w", err)
	}

	connStr := os.Getenv("DATABASE_URL")
	if connStr == "" {
		return nil, fmt.Errorf("la variable DATABASE_URL está vacía")
	}

	db, err := sqlx.Connect("pgx", connStr)
	if err != nil {
		return nil, fmt.Errorf("error conectando a la base de datos: %w", err)
	}
	
	return db, nil
}
package config // O el paquete donde tengas esto

import (
	"fmt"
	"os"

	"github.com/jmoiron/sqlx"
	"github.com/joho/godotenv"
	
	// IMPORTANTE: El puente entre pgx y la librería estándar de Go (sqlx)
	_ "github.com/jackc/pgx/v5/stdlib" 
)

// LoadConfigNeon inicializa y retorna una conexión compatible con sqlx
func LoadConfigNeon() (*sqlx.DB, error) {
	
	// 1. Cargar variables de entorno
	err := godotenv.Load("../../.env") // Ajusta la ruta según dónde llames la función
	if err != nil {
		return nil, fmt.Errorf("error cargando archivo .env: %w", err)
	}

	// 2. Obtener la cadena de conexión de Neon
	connStr := os.Getenv("DATABASE_URL")
	if connStr == "" {
		return nil, fmt.Errorf("la variable DATABASE_URL está vacía")
	}

	// 3. Establecer la conexión usando sqlx.Connect
	// Le pasamos "pgx" como el nombre del driver que importamos arriba
	db, err := sqlx.Connect("pgx", connStr)
	if err != nil {
		return nil, fmt.Errorf("error conectando a la base de datos: %w", err)
	}
	
	return db, nil
}
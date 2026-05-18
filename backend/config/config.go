package config

import (
	"log"
	"os"

	"github.com/joho/godotenv"
)


type Config struct{

	DBHost string
	DBPort string
	DBUser string
	DBPassword string
	DBName string
	
}

func LoadConfig() *Config {

	err := godotenv.Load("../../.env")
	
	if err != nil {
		log.Fatal(err)
	}

	return &Config{
		DBHost: os.Getenv("DB_Host"),
		DBPort: os.Getenv("DB_Port"),
		DBUser: os.Getenv("DB_User"),
		DBPassword: os.Getenv("DB_Password"),
		DBName: os.Getenv("DB_Name"),
	
	}

}
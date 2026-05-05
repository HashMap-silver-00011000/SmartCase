package repository

import (
	"log"
	"github.com/jmoiron/sqlx"
	"backend/internal/models"
)


type TelemetriaRepository struct{
	db *sqlx.DB
}

func NewTelemetriaRepository(db *sqlx.DB) *TelemetriaRepository{
	return &TelemetriaRepository{db:db}
}

//Insertar , consultar , obtener ultimo punto, consultar bus y rango de tiempo 

func (r *TelemetriaRepository) GuardarTelemetria (telemetria *models.Telemetria) error {
	
	_, err :=  r.db.NamedExec(`INSERT INTO telemetria (latitud, longitud, fecha_hora) 
								VALUES 	(:latitud, :longitud, :fecha_hora)`, telemetria)
	if err != nil {
        log.Println("Error guardando en BD:", err)
        return err
    }
    return nil
}


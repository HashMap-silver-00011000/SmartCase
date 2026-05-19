package repository

import (

	"log"

	"github.com/jmoiron/sqlx"
	"backend/internal/models"
)


type ViajeRepository struct{
	db *sqlx.DB
}

func NewViajeCaseRepository(db *sqlx.DB) *ViajeRepository{

	if db == nil {
		panic("No puedes crear un viaje sin una base de datos")
	}
	return &ViajeRepository{db:db}
}

func (r *ViajeRepository) CrearViaje(viaje *models.Viaje) error {

	_, err := r.db.NamedExec(`INSERT INTO viaje (id_viaje, id_caja, id_usuario_conductor, id_sede_origen, id_sede_destino, id_ambulancia,
                                              fecha_inicio, fecha_llegada, estado_viaje) VALUES (:id_viaje, :id_caja, :id_usuario_conductor, :id_sede_origen, :id_sede_destino, :id_ambulancia,
                                              :fecha_inicio, :fecha_llegada, :estado_viaje)`, viaje)

    log.Printf("Error creating viaje: %v", err)
    return err

  }
    

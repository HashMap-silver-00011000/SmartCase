package repository

import (
	"log"

	"backend/internal/models"
	"github.com/jmoiron/sqlx"
)

type AmbulanciaRepository struct {
	db *sqlx.DB
}

func NewAmbulanciaRepository(db *sqlx.DB) *AmbulanciaRepository {
	if db == nil {
		panic("No puedes crear un repositorio sin una base de datos")
	}
	return &AmbulanciaRepository{db: db}
}

func (r *AmbulanciaRepository) CrearAmbulancia(ambulancia *models.Ambulancia) error {
	_, err := r.db.NamedExec(`INSERT INTO ambulancia 
	                        (id_ambulancia, placa, tipo) 
	                        VALUES (:id_ambulancia, :placa, :tipo)`, ambulancia)

	if err != nil {
		log.Printf("Error creating ambulancia: %v", err)
	}
	
	return err
}

func (r *AmbulanciaRepository) BuscarAmbulancia(ambulancia *models.Ambulancia) (*models.Ambulancia, error) {
	var ambulanciaEncontrada models.Ambulancia
	
	// Solicitar la información de la ambulancia buscando por su placa
	err := r.db.Get(&ambulanciaEncontrada, "SELECT * FROM ambulancia WHERE placa = $1", ambulancia.Placa)

	if err != nil {
		log.Printf("Ambulancia no encontrada o error en DB: %v", err)
		return nil, err // retorna error si no encuentra nada (sql.ErrNoRows)
	}
	
	return &ambulanciaEncontrada, nil
}
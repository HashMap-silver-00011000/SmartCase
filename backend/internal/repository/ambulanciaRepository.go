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

	err := r.db.Get(&ambulanciaEncontrada, "SELECT * FROM ambulancia WHERE placa = $1", ambulancia.Placa)

	if err != nil {
		log.Printf("Ambulancia no encontrada o error en DB: %v", err)
		return nil, err // retorna error si no encuentra nada (sql.ErrNoRows)
	}
	
	return &ambulanciaEncontrada, nil
}


func (r *AmbulanciaRepository) ListarAmbulancias() (*[]models.Ambulancia, error) {
	var ambulancias []models.Ambulancia

	err := r.db.Select(&ambulancias, "SELECT * FROM ambulancia")

	if err != nil {
		log.Printf("Error al obtener la lista de ambulancias: %v", err)
		return nil, err
	}
	
	return &ambulancias, nil
}

func (r *AmbulanciaRepository) EliminarAmbulancia(ambulancia *models.Ambulancia) error {
	resultado, err := r.db.NamedExec(`DELETE FROM ambulancia WHERE id_ambulancia = :id_ambulancia`, ambulancia)

	if err != nil {
		log.Printf("Error al eliminar la ambulancia: %v", err)
		return err
	}

	filasAfectadas, _ := resultado.RowsAffected()

	if filasAfectadas == 0 {
		log.Printf("No se encontró la ambulancia con placa %s para eliminar", ambulancia.Placa)
	}

	return nil
}

func (r *AmbulanciaRepository) ActualizarAmbulancia(ambulancia *models.Ambulancia) error {

	_, err := r.db.NamedExec(`UPDATE ambulancia 
	                          SET placa = :placa, tipo = :tipo 
	                          WHERE id_ambulancia = :id_ambulancia`, 
	                          ambulancia)

	if err != nil {
		log.Printf("Error al actualizar la ambulancia: %v", err)
		return err
	}

	return nil
}
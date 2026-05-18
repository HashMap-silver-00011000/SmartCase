package repository

import (
	"log"

	"backend/internal/models"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
)


type SedeRepository struct{
	db *sqlx.DB
}

func NewSedeRepository(db *sqlx.DB) *SedeRepository{

	if db == nil {
		panic("No puedes crear un repositorio sin una base de datos")
	}
	return &SedeRepository{db:db}
}

func (r *SedeRepository) CrearSede(sede *models.Sede) error {

	_, err := r.db.NamedExec(`INSERT INTO sede 
    						(id_sede, id_clinica, nombre) 
							VALUES (:id_sede, :id_clinica, :nombre)`, sede)

	if err != nil {
		log.Printf("Error creating sede: %v", err)
	}
	return err
}

func (r *SedeRepository) BuscarSede(sede *models.Sede) (*models.Sede, error) {

	var encontrada models.Sede
	err := r.db.Get(&encontrada, "SELECT * FROM sede WHERE id_sede = $1", sede.IDSede)

	if err != nil {
		log.Print(err)
		return nil, err
	}
	return &encontrada, nil
}

func (r *SedeRepository) ListarSede() (*[]models.Sede, error) {
	var sedes []models.Sede

	err := r.db.Select(&sedes, "SELECT * FROM sede")

	if err != nil {
		log.Printf("Error al obtener la lista de sedes: %v", err)
		return nil, err
	}
	return &sedes, nil
}

func (r *SedeRepository) ListarSedesPorClinica(idClinica uuid.UUID) (*[]models.Sede, error) {
	
	var sedes []models.Sede

	err := r.db.Select(&sedes, "SELECT * FROM sede WHERE id_clinica = $1", idClinica)

	if err != nil {
		log.Printf("Error al obtener sedes de la clínica: %v", err)
		return nil, err
	}
	return &sedes, nil
}

func (r *SedeRepository) EliminarSede(sede *models.Sede) error {

	resultado, err := r.db.NamedExec(`DELETE FROM sede WHERE id_sede = :id_sede`, sede)

	if err != nil {
        log.Printf("Error al eliminar la sede: %v", err)
        return err
    }

	filasAfectadas, _ := resultado.RowsAffected()

	if filasAfectadas == 0 {
        // No hubo error de SQL
        log.Printf("No se encontró la sede con Nombre %s para eliminar", sede.Nombre)
    }

	return nil

}

func (r *SedeRepository) ActualizarSede(sede *models.Sede) error {

	_, err := r.db.NamedExec(`UPDATE sede 
                          SET nombre = :nombre 
                          WHERE id_sede = :id_sede`,
		sede)

	if err != nil {
        log.Printf("Error en la solicitud: %v", err)
        return err
    }

	return nil
}

package repository

import (

	"log"

	"github.com/jmoiron/sqlx"
	"backend/internal/models"
)


type ClinicaRepository struct{
	db *sqlx.DB
}

func NewClinicaRepository(db *sqlx.DB) *ClinicaRepository{

	if db == nil {
		panic("No puedes crear un repositorio sin una base de datos")
	}
	return &ClinicaRepository{db:db}
}

func (r *ClinicaRepository) CrearClinica(clinica *models.Clinica) error {

	_ ,err := r.db.NamedExec(`INSERT INTO clinica 
    						(id_clinica, nombre) 
							VALUES (:id_clinica, :nombre)`, clinica)

    log.Printf("Error creating clinica: %v", err)
    return err
    
}

func (r *ClinicaRepository) BuscarClinica(clinica *models.Clinica) (*models.Clinica, error){

	var ClinicaNombre models.Clinica
	//Solicitar la informacion de la clinica si existe el nombre
	err := r.db.Get(&ClinicaNombre, "SELECT * FROM clinica WHERE id_clinica = $1", clinica.IDClinica)

	if err != nil {
    	log.Print(err)
		return nil, err // retorna error si no encuentra nada (sql.ErrNoRows)
	}
	return &ClinicaNombre, nil
}

func (r *ClinicaRepository) ListarClinica() (*[]models.Clinica, error) {
    var clinicas []models.Clinica

    err := r.db.Select(&clinicas, "SELECT * FROM clinica")
    
    if err != nil {
        log.Printf("Error al obtener la lista de clínicas: %v", err)
        return nil, err
    }
    return &clinicas, nil
}

func (r *ClinicaRepository) EliminarClinica(clinica *models.Clinica) error {

	resultado ,err := r.db.NamedExec(`DELETE FROM clinica WHERE id_clinica = :id_clinica`, clinica)

	if err != nil {
        log.Printf("Error al eliminar la clinica: %v", err)
        return err
    }

	filasAfectadas, _ := resultado.RowsAffected()

	if filasAfectadas == 0 {
        // No hubo error de SQL
        log.Printf("No se encontró la clinica con Nombre %s para eliminar", clinica.Nombre)
    }

	return nil

}

func (r *ClinicaRepository) ActualizarClinica(clinica *models.Clinica) error {

	_, err := r.db.NamedExec(`UPDATE clinica 
                          SET nombre = :nombre 
                          WHERE id_clinica = :id_clinica`, 
                          clinica)

	if err != nil {
        log.Printf("Error actualizando: %v", err)
        return err
    }

	return nil
}

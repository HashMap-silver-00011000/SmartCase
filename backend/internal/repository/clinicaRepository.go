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

	var ClinicaNombre models.clinica
	//Solicitar la informacion de la clinica si existe el correo
	err := r.db.Get(&ClinicaNombre, "SELECT * FROM clinica WHERE nombre = $1", clinica.nombre)

	if err != nil {
    	log.Fatal(err)
		return nil, err // retorna error si no encuentra nada (sql.ErrNoRows)
	}
	return &ClinicaNombre, nil
}

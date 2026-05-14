package repository

import (

	"log"

	"github.com/jmoiron/sqlx"
	"backend/internal/models"
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

	_ ,err := r.db.NamedExec(`INSERT INTO Sede 
    						(id_Sede, id_clinica nombre) 
							VALUES (:id_Sede, :id_clinica, :nombre)`, sede)

    log.Printf("Error creating Sede: %v", err)
    return err
    
}

func (r *SedeRepository) BuscarSede(clinica *models.Sede) (*models.Sede, error){

	var SedeNombre models.Sede
	//Solicitar la informacion de la clinica si existe el correo
	err := r.db.Get(&SedeNombre, "SELECT * FROM Sede WHERE nombre = $1", Sede.nombre)

	if err != nil {
    	log.Fatal(err)
		return nil, err // retorna error si no encuentra nada (sql.ErrNoRows)
	}
	return &SedeNombre, nil
}

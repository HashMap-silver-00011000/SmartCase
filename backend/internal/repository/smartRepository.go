package repository

import (

	"log"

	"github.com/jmoiron/sqlx"
	"backend/internal/models"
)


type SmartRepository struct{
	db *sqlx.DB
}

func NewSmartCaseRepository(db *sqlx.DB) *SmartRepository{

	if db == nil {
		panic("No puedes crear un caja sin una base de datos")
	}
	return &SmartRepository{db:db}
}

func (r *SmartRepository) CrearCaja(smart *models.SmartCase) error {

	_ ,err := r.db.NamedExec(`INSERT INTO SmartCase 
    						(id_caja, estado_solenoide, organo) 
							VALUES (:id_caja, :estado_solenoide, :organo)`, smart)

    log.Printf("Error creating SmartCase: %v", err)
    return err
    
}

package repository

import (
	"log"

	"backend/internal/models"
	"github.com/jmoiron/sqlx"
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

	_ ,err := r.db.NamedExec(`INSERT INTO smartcase 
    						(id_caja, estado_solenoide, organo) 
							VALUES (:id_caja, :estado_solenoide, :organo)`, smart)

    log.Printf("Error creating SmartCase: %v", err)
    return err
    
}

func (r *SmartRepository) BuscarSmartCase(smart *models.SmartCase) (*models.SmartCase, error) {

	var smartCase models.SmartCase
	err := r.db.Get(&smartCase, "SELECT * FROM smartcase WHERE id_caja = $1", smart.IDCaja)

	if err != nil {
		log.Print(err)
		return nil, err
	}
	return &smartCase, nil
}

func (r *SmartRepository) ListarSmartCase() (*[]models.SmartCase, error) {
	
	var SmartCases []models.SmartCase

	err := r.db.Select(&SmartCases, "SELECT * FROM smartcase")

	if err != nil {
		log.Printf("Error al obtener la lista de Cajas: %v", err)
		return nil, err
	}
	return &SmartCases, nil
}

func (r *SmartRepository) ListarSmartCases() (*[]models.SmartCase, error) {
	
	var SmartCases []models.SmartCase

	err := r.db.Select(&SmartCases, "SELECT * FROM smartcase ")

	if err != nil {
		log.Printf("Error al obtener SmartCases de la clínica: %v", err)
		return nil, err
	}
	return &SmartCases, nil
}

func (r *SmartRepository) EliminarSmartCase(smart *models.SmartCase) error {

	resultado, err := r.db.NamedExec(`DELETE FROM smartcase WHERE id_caja = :id_caja`, smart)

	if err != nil {
        log.Printf("Error al eliminar la smart: %v", err)
        return err
    }

	filasAfectadas, _ := resultado.RowsAffected()

	if filasAfectadas == 0 {
        // No hubo error de SQL
        log.Printf("No se encontró la caja %s para eliminar", smart.IDCaja)
    }

	return nil

}

func (r *SmartRepository) ActualizarSmartCase(smart *models.SmartCase) error {

	_, err := r.db.NamedExec(`UPDATE smartcase 
                          SET nombre = :nombre 
                          WHERE id_caja = :id_caja`,
		smart)

	if err != nil {
        log.Printf("Error en la solicitud: %v", err)
        return err
    }

	return nil
}




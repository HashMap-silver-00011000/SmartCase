package service

import (
	"backend/internal/models"
	"backend/internal/repository"
	"log"
)

type SmartService struct{
	r  *repository.SmartRepository
}

func NewSmartService(r *repository.SmartRepository) *SmartService {
	return &SmartService{r:r}
}

func (s *SmartService)  CrearSmart(caja *models.SmartCase) error {

	err := s.r.CrearCaja(caja) //mejorar trato con el error
	log.Print(err)
	return err

}

func (s *SmartService)  BuscarSmartCase(smart *models.SmartCase) (*models.SmartCase ,error) {
	
	smartEncontrado ,err := s.r.BuscarSmartCase(smart)
	if err != nil {
		log.Print(err)
		return nil, err
	}
	return smartEncontrado, err
}

func (s *SmartService)  ListarSmartCase() (*[]models.SmartCase,error) {
	
	smartCase , err := s.r.ListarSmartCase()
	if err != nil {
		log.Print(err)
		return nil, err
	}
	return smartCase, err
}

func (s *SmartService) EliminarSmartCase(smart *models.SmartCase) error {
	
	err := s.r.EliminarSmartCase(smart)
	if err != nil {
		log.Printf("Error en servicio al eliminar caja: %v", err)
		return  err
	}
	
	return nil
}

func (s *SmartService) ActualizarSmartCase(smart *models.SmartCase) error {
	
	err := s.r.ActualizarSmartCase(smart)
	if err != nil {
		log.Printf("Error en servicio al actualizar caja: %v", err)
		return  err
	}

	return nil
}


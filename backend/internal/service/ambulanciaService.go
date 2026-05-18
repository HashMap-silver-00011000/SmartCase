package service

import (
	"log"

	"backend/internal/models"
	"backend/internal/repository"
)

type AmbulanciaService struct {
	r *repository.AmbulanciaRepository
}

func NewAmbulanciaService(r *repository.AmbulanciaRepository) *AmbulanciaService {
	return &AmbulanciaService{r: r}
}

func (s *AmbulanciaService) CrearAmbulancia(ambulancia *models.Ambulancia) error {
	
	err := s.r.CrearAmbulancia(ambulancia)
	if err != nil {
		log.Printf("Error en servicio al crear ambulancia: %v", err)
		return err
	}
	
	return nil
}

func (s *AmbulanciaService) BuscarAmbulancia(ambulancia *models.Ambulancia) (*models.Ambulancia, error) {
	
	ambulanciaEncontrada, err := s.r.BuscarAmbulancia(ambulancia)
	if err != nil {
		log.Printf("Error en servicio al buscar ambulancia: %v", err)
		return nil, err
	}
	
	return ambulanciaEncontrada, nil
}

func (s *AmbulanciaService) ListarAmbulancias() (*[]models.Ambulancia, error) {
	
	ambulancias, err := s.r.ListarAmbulancias()
	if err != nil {
		log.Printf("Error en servicio al listar ambulancias: %v", err)
		return nil, err
	}
	
	return ambulancias, nil
}

func (s *AmbulanciaService) EliminarAmbulancia(ambulancia *models.Ambulancia) error {
	
	err := s.r.EliminarAmbulancia(ambulancia)
	if err != nil {
		log.Printf("Error en servicio al eliminar ambulancia: %v", err)
		return err
	}
	
	return nil
}

func (s *AmbulanciaService) ActualizarAmbulancia(ambulancia *models.Ambulancia) error {
	
	err := s.r.ActualizarAmbulancia(ambulancia)
	if err != nil {
		log.Printf("Error en servicio al actualizar ambulancia: %v", err)
		return err
	}

	return nil
}
package service

import (
	"backend/internal/models"
	"backend/internal/repository"
	"log"
)

type AmbulanciaService struct {
	r *repository.AmbulanciaRepository
}

func NewAmbulanciaService(r *repository.AmbulanciaRepository) *AmbulanciaService {
	return &AmbulanciaService{r: r}
}

func (s *AmbulanciaService) NuevaAmbulancia(ambulancia *models.Ambulancia) error {
	
	err := s.r.CrearAmbulancia(ambulancia)
	if err != nil {
		log.Printf("Error en servicio al crear ambulancia: %v", err)
	}
	
	return err
}

func (s *AmbulanciaService) BuscarAmbulancia(ambulancia *models.Ambulancia) (*models.Ambulancia, error) {
	
	amb, err := s.r.BuscarAmbulancia(ambulancia)
	if err != nil {
		log.Printf("Error en servicio al buscar ambulancia: %v", err)
		return nil, err
	}
	
	return amb, nil
}


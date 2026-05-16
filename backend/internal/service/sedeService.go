package service

import (
	"backend/internal/models"
	"backend/internal/repository"
	"log"
)


type SedeService struct {
	r *repository.SedeRepository
}

func NewSedeService (r *repository.SedeRepository) *SedeService {
	return &SedeService{r:r}
}

func (s *SedeService)  NuevaSede(sede *models.Sede) error {
	
	err := s.r.CrearSede(sede)
	if err != nil {
		log.Print(err)
	}
	return  err
}
package service

import (
	"backend/internal/models"
	"backend/internal/repository"
	"log"

	"github.com/google/uuid"
)


type SedeService struct {
	r *repository.SedeRepository
}

func NewSedeService (r *repository.SedeRepository) *SedeService {
	return &SedeService{r:r}
}

func (s *SedeService)  CrearSede(sede *models.Sede) error {
	
	err := s.r.CrearSede(sede)
	if err != nil {
		log.Printf("error al crear sede en DB: %v", err)
	}
	return  err
}

func (s *SedeService)  BuscarSede(sede *models.Sede) (*models.Sede ,error) {
	
	sedeEncontrada ,err := s.r.BuscarSede(sede)
	if err != nil {
		log.Printf("No es posible encontrar la sede en DB: %v", err)
		return nil, err
	}
	return sedeEncontrada, nil
}

func (s *SedeService) ListarSede() (*[]models.Sede, error) {

	sedes, err := s.r.ListarSede()
	if err != nil {
		log.Printf("No es posible encontrar las sedes en DB: %v", err)
		return nil, err
	}
	return sedes, err
}

func (s *SedeService) ListarSedesPorClinica(idClinica uuid.UUID) (*[]models.Sede, error) {

	sedes, err := s.r.ListarSedesPorClinica(idClinica)
	if err != nil {
		log.Printf("No es posible listar sedes de la clínica: %v", err)
		return nil, err
	}
	return sedes, nil
}

func (s *SedeService) EliminarSede(sede *models.Sede) error {
	
	err := s.r.EliminarSede(sede)
	if err != nil {
		log.Printf("Error al eliminar la sede en DB: %v", err)
		return  err
	}
	
	return nil
}

func (s *SedeService) ActualizarSede(sede *models.Sede) error {
	
	err := s.r.ActualizarSede(sede)
	if err != nil {
		log.Printf("Error en servicio al actualizar clinica: %v", err)
		return  err
	}

	return nil
}


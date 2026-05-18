package service

import (
	"backend/internal/models"
	"backend/internal/repository"

	"log"
)


type ClinicaService struct {
	r *repository.ClinicaRepository
}

func NewClinicaService (r *repository.ClinicaRepository) *ClinicaService {
	return &ClinicaService{r:r}
}

func (s *ClinicaService)  CrearClinica (clinica *models.Clinica) error {
	
	err := s.r.CrearClinica(clinica)
		if err != nil {
			log.Print(err)
			return err

	}
	return nil
}

func (s *ClinicaService)  BuscarClinica (clinica *models.Clinica) (*models.Clinica ,error) {
	
	clinicaEncontrada ,err := s.r.BuscarClinica(clinica)
	if err != nil {
		log.Print(err)
		return nil, err
	}
	return clinicaEncontrada, err
}

func (s *ClinicaService)  ListarClinica() (*[]models.Clinica,error) {
	
	clinicas , err := s.r.ListarClinica()
	if err != nil {
		log.Print(err)
		return nil, err
	}
	return clinicas, err
}

func (s *ClinicaService) EliminarClinica(clinica *models.Clinica) error {
	
	err := s.r.EliminarClinica(clinica)
	if err != nil {
		log.Printf("Error en servicio al eliminar clinica: %v", err)
		return  err
	}
	
	return nil
}

func (s *ClinicaService) ActualizarClinica(clinica *models.Clinica) error {
	
	err := s.r.ActualizarClinica(clinica)
	if err != nil {
		log.Printf("Error en servicio al actualizar clinica: %v", err)
		return  err
	}

	return nil
}


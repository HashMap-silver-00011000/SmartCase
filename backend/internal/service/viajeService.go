package service

import (
	"backend/internal/models"
	"backend/internal/repository"
	"log"
)

type ViajeService struct {
	r *repository.ViajeRepository
}

func NewViajeService(r *repository.ViajeRepository) *ViajeService{
	return &ViajeService{r:r}
}

func(s *ViajeService) CrearViaje(viaje *models.Viaje) error{

	err :=  s.r.CrearViaje(viaje)

	if err != nil {
		log.Printf("Error en service : %v", err)
		return err
	}

	return nil
}
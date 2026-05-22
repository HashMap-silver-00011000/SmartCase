package service

import (
	"backend/internal/models"
	"backend/internal/repository"
	"log"

	"github.com/google/uuid"
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

func (s *ViajeService) ListarPorEstado(viaje *models.Viaje) (*[]models.Viaje, error) {
	
	listaViaje , err := s.r.ListarPorEstado(viaje)

	if err != nil {
		log.Printf("Error en service : %v", err)
		return nil, err
	}

	return listaViaje, nil
}

func (s *ViajeService) ListarPorUsuario(id_usuario_conductor uuid.UUID) (*[]models.Viaje, error) {

	listaViaje , err := s.r.ListarPorUsuario(id_usuario_conductor)

	if err != nil {
		log.Printf("Error en service : %v", err)
		return nil, err
	}

	return listaViaje, nil
}

func (s *ViajeService) ListarPorReceptor(idUsuarioReceptor uuid.UUID) (*[]models.Viaje, error) {
	listaViaje, err := s.r.ListarPorReceptor(idUsuarioReceptor)
	if err != nil {
		log.Printf("Error en service receptor: %v", err)
		return nil, err
	}
	return listaViaje, nil
}
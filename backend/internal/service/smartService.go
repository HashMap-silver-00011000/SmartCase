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
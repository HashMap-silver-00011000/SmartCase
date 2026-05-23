package service

import (
	"backend/internal/models"
	"backend/internal/repository"
	"crypto/rand"
	"fmt"
	"log"
	"math/big"

	"github.com/google/uuid"
)

type ViajeService struct {
	r *repository.ViajeRepository
}

func NewViajeService(r *repository.ViajeRepository) *ViajeService{
	return &ViajeService{r:r}
}

func(s *ViajeService) CrearViaje(viaje *models.Viaje) error{

	max := big.NewInt(1000000)
	n, err := rand.Int(rand.Reader, max)
	if err != nil {
		log.Println("Error al generar el pin:", err)
		return err
	}

	pinFormateado := fmt.Sprintf("%06d", n)
	log.Print(pinFormateado)
	viajePin := &models.Viaje{
		IDViaje:            viaje.IDViaje,
		IDCaja:             viaje.IDCaja,
		IDUsuarioConductor: viaje.IDUsuarioConductor,
		IDUsuarioReceptor:  viaje.IDUsuarioReceptor,
		IDSedeOrigen:       viaje.IDSedeOrigen,
		IDSedeDestino:      viaje.IDSedeDestino,
		IDAmbulancia:       viaje.IDAmbulancia,
		FechaInicio:        viaje.FechaInicio,
		FechaLlegada:       viaje.FechaLlegada,
		EstadoViaje:        viaje.EstadoViaje,
		PinEntrega:         pinFormateado,
	}

	err =  s.r.CrearViaje(viajePin)

	if err != nil {
		log.Printf("Error en service : %v", err)
		return err
	}

	return nil
}

func (s *ViajeService) ListarPorEstado(viaje *models.ViajeConductor) (*[]models.ViajeConductor, error) {
	
	listaViaje , err := s.r.ListarPorEstado(viaje)

	if err != nil {
		log.Printf("Error en service : %v", err)
		return nil, err
	}

	return listaViaje, nil
}

func (s *ViajeService) ListarPorUsuario(id_usuario_conductor uuid.UUID) (*[]models.ViajeConductor, error) {

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


func (s *ViajeService) ActualizarEstadoViaje(viaje *models.Viaje) error {

	err := s.r.ActualizarEstadoViaje(viaje)
	if err != nil {
		log.Printf("Error en servicio al actualizar caja: %v", err)
		return  err
	}
	return nil
}

func(s *ViajeService) ComprobarPin(pin *models.Viaje) (bool , error){

	pinViaje, err := s.r.ComprobarPin(pin)

	if err != nil {
		log.Printf("Error en servicio al verificar pin: %v", err)
		return  false, err
	}

	if pinViaje.PinEntrega != pin.PinEntrega {
		if err != nil {
			log.Printf("Error en servicio al verificar pin: %v", err)
		return  false, err
		}
	}
	return true, nil
	
}

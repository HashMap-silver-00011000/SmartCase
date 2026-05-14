package models

import (
	"time"

	"github.com/google/uuid"
)

// Viaje representa la tabla viaje
type Viaje struct {
	IDViaje            uuid.UUID       `db:"id_viaje" json:"id_viaje"`
	IDCaja             uuid.UUID       `db:"id_caja" json:"id_caja"`
	IDUsuarioConductor uuid.UUID       `db:"id_usuario_conductor" json:"id_usuario_conductor"`
	IDSedeOrigen       uuid.UUID       `db:"id_sede_origen" json:"id_sede_origen"`
	IDSedeDestino      uuid.UUID       `db:"id_sede_destino" json:"id_sede_destino"`
	IDAmbulancia       uuid.UUID       `db:"id_ambulancia" json:"id_ambulancia"`
	FechaInicio        time.Time       `db:"fecha_inicio" json:"fecha_inicio"`
	FechaLlegada       *time.Time      `db:"fecha_llegada" json:"fecha_llegada,omitempty"`
	EstadoViaje        *string         `db:"estado_viaje" json:"estado_viaje,omitempty"`
}
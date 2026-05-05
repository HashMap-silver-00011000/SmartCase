package models

import "github.com/google/uuid"

type Bus struct {
	IDBus              uuid.UUID `db:"id_bus"`
	IDUsuarioConductor uuid.UUID `db:"id_usuario_conductor"`
	IDRutaActual       *uuid.UUID  `db:"id_ruta_actual"`
}
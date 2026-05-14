package models

import "github.com/google/uuid"

type Sede struct {
	IDSede    uuid.UUID `db:"id_sede" json:"id_sede"`
	IDClinica uuid.UUID `db:"id_clinica" json:"id_clinica"`
	Nombre    string    `db:"nombre" json:"nombre"`
}
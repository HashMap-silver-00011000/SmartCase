package models

import "github.com/google/uuid"

type Clinica struct {
	IDClinica uuid.UUID `db:"id_clinica" json:"id_clinica"`
	Nombre    string    `db:"nombre" json:"nombre"`
}
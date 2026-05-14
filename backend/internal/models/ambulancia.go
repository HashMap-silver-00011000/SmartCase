package models

import "github.com/google/uuid"

type Ambulancia struct {
	IDAmbulancia uuid.UUID `db:"id_ambulancia" json:"id_ambulancia"`
	Placa        string    `db:"placa" json:"placa"`
	Tipo         string    `db:"tipo" json:"tipo"`
}
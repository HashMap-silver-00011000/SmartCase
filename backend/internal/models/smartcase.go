package models

import "github.com/google/uuid"

type SmartCase struct {
	IDCaja          uuid.UUID `db:"id_caja" json:"id_caja"`
	EstadoSolenoide string    `db:"estado_solenoide" json:"estado_solenoide"`
	Organo          string    `db:"organo" json:"organo"`
}
package repository

import (
	"log" 

	"github.com/jmoiron/sqlx"
	"backend/internal/models"

)


type RutaRepository struct{
	db *sqlx.DB
}

func NewRutaRepository (db *sqlx.DB) *RutaRepository{
	return &RutaRepository{db:db}
}

func (r *RutaRepository) CrearRuta (ruta *models.Ruta)  error {
	_ ,err := r.db.NamedExec(`INSERT INTO ruta (codigo, nombre, activa)
				VALUES (:codigo, :nombre, :activa)`, ruta)
	log.Print(err)
	return  err
}


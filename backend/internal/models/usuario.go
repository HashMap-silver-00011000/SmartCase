package models

import (
		"github.com/google/uuid")

// Usuario representa la tabla usuario
type Usuario struct {
	IDUsuario      uuid.UUID `db:"id_usuario" json:"id_usuario"`
	IDSede         uuid.UUID `db:"id_sede" json:"id_sede"`
	Nombre         string    `db:"nombre_completo" json:"nombre_completo"`
	Rol            string    `db:"rol" json:"rol"` 
	Correo          string    `db:"email" json:"email"`
	Password       string    `db:"password" json:"-"` 
}


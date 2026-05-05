package models

import "github.com/google/uuid"

type Usuario struct {
	ID 			uuid.UUID  		`db:"id_usuario"	json:"id_usuario"`
	Nombre 		string			`db:"nombre" 		json:"nombre"`
	Apellidos 	string			`db:"apellidos" 	json:"apellidos"`
	Rol 		string			`db:"rol" 			json:"rol"`
	Email 		string			`db:"email" 		json:"email"`
	Password 	string			`db:"password" 		json:"email"`
}


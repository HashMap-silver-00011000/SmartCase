package repository

import (

	"log"

	"github.com/jmoiron/sqlx"
	"backend/internal/models"
)


type UsuarioRepository struct{
	db *sqlx.DB
}

func NewUsuarioRepository(db *sqlx.DB) *UsuarioRepository{

	if db == nil {
		panic("No puedes crear un repositorio sin una base de datos")
	}
	return &UsuarioRepository{db:db}
}

func (r *UsuarioRepository) CrearUsuario(usuario *models.Usuario) error {

	_ ,err := r.db.NamedExec(`INSERT INTO usuario 
    						(id_usuario, nombre_completo, email, password, rol) 
							VALUES (:id_usuario, :nombre_completo, :email, :password, :rol)`, usuario)

    log.Printf("Error creating user: %v", err)
    return err
    
}

func (r *UsuarioRepository) BuscarPorEmail(usuario *models.Usuario) (*models.Usuario, error){

	var usuarioEmail models.Usuario
	//Solicitar la informacion del usuario si existe el correo
	err := r.db.Get(&usuarioEmail, "SELECT * FROM usuario WHERE email = $1", usuario.Correo)

	if err != nil {
    	log.Fatal(err)
		return nil, err // retorna error si no encuentra nada (sql.ErrNoRows)
	}
	return &usuarioEmail, nil
}



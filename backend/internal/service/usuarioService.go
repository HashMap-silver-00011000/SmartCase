package service

import (
	"backend/internal/models"
	"backend/internal/repository"
	"errors"
	"log"

	"golang.org/x/crypto/bcrypt"
)

type UsuarioService struct{
	r *repository.UsuarioRepository 
}

func NewUsuarioService (r *repository.UsuarioRepository) *UsuarioService {
	return &UsuarioService{r:r}
}

func (s *UsuarioService) NuevoUsuario(usuario *models.Usuario) error {
	err := s.r.CrearUsuario(usuario)
	return  err

}

func (s *UsuarioService) ListarConductores() (*[]models.Usuario, error) {
	return s.r.ListarPorRol("coductor")
}

func (s *UsuarioService) ListarReceptores() (*[]models.Usuario, error) {
	return s.r.ListarPorRol("receptor")
}

func (s *UsuarioService) Autenticar(usuarioE *models.Usuario) (*models.Usuario, error) {

	usuario , err :=  s.r.BuscarPorEmail(usuarioE)
	
	if err != nil {
		return nil, errors.New("Credenciales no validas")
	}

	// HashPassword, _ := bcrypt.GenerateFromPassword([]byte(usuarioE.Password), bcrypt.DefaultCost)

	err = bcrypt.CompareHashAndPassword([]byte(usuario.Password), []byte(usuarioE.Password))

	if err != nil {
		log.Printf("Error de validacion en Password %v",  err)
		return nil, err
	}

	// if usuario.Password != string(HashPassword) {
	// 	return nil, errors.New("Credenciales no validas")
	// }

	return usuario, nil
}

package handlers

import (
	"backend/internal/models"
	"backend/internal/service"
	
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type AuthHandler struct {
	svc *service.UsuarioService
}

func NewAuthHandler(svc *service.UsuarioService) *AuthHandler {
	return &AuthHandler{svc: svc}
}

type RegistroInput struct {
	Nombre    string `json:"nombre_completo"`
	Rol     string    `json:"rol"`
	Email     string `json:"email"`
	Password  string `json:"password"`
}

type LoginInput struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

func (h *AuthHandler) Registro(c *gin.Context) {

	var registroIput RegistroInput

	if err := c.ShouldBindJSON(&registroIput); err != nil {
		c.JSON(400, gin.H{"error ": "JSON invalido"})
		return
	}

	
	
	usuario := &models.Usuario{

		IDUsuario:        uuid.New(),
		Nombre:    registroIput.Nombre,
		Rol  :       registroIput.Rol,
		Correo:     registroIput.Email,
		Password:  registroIput.Password,
	
	}

	err := h.svc.NuevoUsuario(usuario)
	if err != nil {
		c.JSON(500, gin.H{"error": "no se pudo crear el usuario"})
		return
	}

	c.JSON(201, gin.H{"mensaje": "usuario creado"})

}

func (h *AuthHandler) Login(c *gin.Context) {

	var loginInput LoginInput

	if err := c.ShouldBindJSON(&loginInput); err != nil {
		c.JSON(400, gin.H{"error ": "JSON invalido"})
		return
	}

	usuario := &models.Usuario{
		Correo:    loginInput.Email,
		Password: loginInput.Password,
	}

	_, err := h.svc.Autenticar(usuario)

	if err != nil {
		c.JSON(403, gin.H{"error": "Usuario no valido"})
	}
	c.JSON(200, gin.H{"Mensaje": "Usuario ingresado"})

}

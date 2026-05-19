package handlers

import (
	"backend/internal/models"
	"backend/internal/service"
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
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

	Email    	string 		`json:"email"`
	Password 	string 		`json:"password"`
}

func (h *AuthHandler) Registro(c *gin.Context) {

	var registroIput RegistroInput

	if err := c.ShouldBindJSON(&registroIput); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error ": "JSON invalido"})
		return
	}

	HashPassword, bad := bcrypt.GenerateFromPassword([]byte(registroIput.Password), bcrypt.DefaultCost)
	
	if bad != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error" :  "Error al encriptar Password"})
		return
	}

	usuario := &models.Usuario{

		IDUsuario:        uuid.New(),
		Nombre:    registroIput.Nombre,
		Rol  :       registroIput.Rol,
		Correo:     registroIput.Email,
		Password:  string(HashPassword),
	
	}

	err := h.svc.NuevoUsuario(usuario)
	
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "no se pudo crear el usuario"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"mensaje": "usuario creado"})

}

func (h *AuthHandler) Login(c *gin.Context) {

	var loginInput LoginInput

	if err := c.ShouldBindJSON(&loginInput); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error ": "JSON invalido"})
		return
	}

	usuario := &models.Usuario{
		Correo:   loginInput.Email,
		Password: loginInput.Password,
	}

	usuarioAuth, err := h.svc.Autenticar(usuario)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Usuario no valido"})
		return
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"sub": usuarioAuth.IDUsuario.String(),
		"exp": time.Now().Add(time.Hour * 24).Unix(),
		"rol": usuarioAuth.Rol,
	})

	tokenString, bad := token.SignedString([]byte(os.Getenv("SECRET")))
	if bad != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error al firmar el token"})
		return
	}

	// Domain vacío: válido al conectar por IP (móvil en red local). La app también usa `token` en JSON.
	c.SetCookie("smart_session", tokenString, 3600, "/", "", false, true)

	c.JSON(http.StatusOK, gin.H{
		"Mensaje": "Usuario ingresado",
		"rol":     usuarioAuth.Rol,
		"token":   tokenString,
	})

}

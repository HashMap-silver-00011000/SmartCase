package handlers

import (
	"backend/internal/models"
	"backend/internal/service"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type AmbulanciaHandler struct {
	s *service.AmbulanciaService
}

func NewAmbulanciaHandler(s *service.AmbulanciaService) *AmbulanciaHandler {
	return &AmbulanciaHandler{s: s}
}

type AmbulanciaInput struct {
	Placa string `json:"placa"`
	Tipo  string `json:"tipo"`
}

func (h *AmbulanciaHandler) FormAmbulancia(c *gin.Context) {
	var inputAmbulancia AmbulanciaInput

	if err := c.ShouldBindJSON(&inputAmbulancia); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "sintaxis invalida"})
		return 
	}

	
	ambulancia := &models.Ambulancia{
		IDAmbulancia: uuid.New(),
		Placa:        inputAmbulancia.Placa,
		Tipo:         inputAmbulancia.Tipo,
	}

	err := h.s.NuevaAmbulancia(ambulancia)

	if err != nil {
		c.JSON(http.StatusConflict, gin.H{"error": "Rechazo solicitud, posible placa duplicada"})
		return 
	}

	c.JSON(http.StatusCreated, gin.H{"Mensaje": "Ambulancia Creada"})
}
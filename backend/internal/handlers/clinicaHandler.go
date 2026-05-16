package handlers

import (
	"backend/internal/models"
	"backend/internal/service"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type ClinicaHandler struct {
	s  *service.ClinicaService
}

func NewClinicaHandler (s *service.ClinicaService) *ClinicaHandler{
	return &ClinicaHandler{s:s}
}

type ClinicaInput struct {
	Nombre 	string `json:"nombre"`
}

func (h *ClinicaHandler) CrearClinica (c *gin.Context) {
	var inputClinica ClinicaInput

	if err := c.ShouldBindJSON(&inputClinica); err != nil {
		c.JSON(400, gin.H{"error" : "sintaxis invalida"})
		return
	}

	clinica := &models.Clinica{
		IDClinica: uuid.New(),
		Nombre: inputClinica.Nombre,
	}

	err := h.s.CrearClinica(clinica)

	if err != nil {
		c.JSON(403, gin.H{"error" : "Rechazo solicitud"})
		return
	}

	c.JSON(201, gin.H{"Mensaje" : "Clinica Creada"})
}




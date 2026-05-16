package handlers

import (
	"backend/internal/models"
	"backend/internal/service"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type SedeHandler struct {
	s  *service.SedeService
}

func NewSedeHandler (s *service.SedeService) *SedeHandler{
	return &SedeHandler{s:s}
}

type requestSede struct {
	IDClinica uuid.UUID `json:"id_clinica"`
	Nombre 	string `json:"nombre"`
}

func (h *SedeHandler) CrearSede (c *gin.Context) {
	var inputSede requestSede

	if err := c.ShouldBindJSON(&inputSede); err != nil {
		c.JSON(400, gin.H{"error" : "sintaxis invalida"})
		return
	}

	sede := &models.Sede{
		IDSede : uuid.New(),
		IDClinica: inputSede.IDClinica,
		Nombre: inputSede.Nombre,
	}

	err := h.s.NuevaSede(sede)

	if err != nil {
		c.JSON(403, gin.H{"error" : "Rechazo solicitud"})//Evitar que los nombres se repitan en service
		return
	}

	c.JSON(201, gin.H{"Mensaje" : "Sede Creada"})
}


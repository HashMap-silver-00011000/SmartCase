package handlers

import (
	"backend/internal/models"
	"backend/internal/service"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type SmartHandler struct {
	s  *service.SmartService
}

func NewSmartHandler (s *service.SmartService) *SmartHandler{
	return &SmartHandler{s:s}
}

type requestSmart struct {
	
	EstadoSolenoide string    `json:"estado_solenoide"`
	Organo          string    `json:"organo"`
}

func (h *SmartHandler) CrearSmart (c *gin.Context) {

	var inputSmart requestSmart

	if err := c.ShouldBindJSON(&inputSmart); err != nil {
		c.JSON(400, gin.H{"error" : "sintaxis invalida"})
		return
	}

	smart := &models.SmartCase{
		IDCaja : uuid.New(),
		EstadoSolenoide: inputSmart.EstadoSolenoide,
		Organo: inputSmart.Organo,
	}

	err := h.s.CrearSmart(smart)

	if err != nil {
		c.JSON(403, gin.H{"error" : "Rechazo solicitud"})//Evitar que la caja este en dos viajes
		return
	}

	c.JSON(201, gin.H{"Mensaje" : "Caja Creada"})
}


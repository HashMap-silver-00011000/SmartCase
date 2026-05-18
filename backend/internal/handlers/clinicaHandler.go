package handlers

import (
	"net/http"
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

func (h *ClinicaHandler) CrearClinica(c *gin.Context) {
	var inputClinica ClinicaInput

	if err := c.ShouldBindJSON(&inputClinica); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error" : "sintaxis invalida"})
		return
	}

	clinica := &models.Clinica{
		IDClinica: uuid.New(),
		Nombre: inputClinica.Nombre,
	}

	err := h.s.CrearClinica(clinica)

	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error" : "Rechazo solicitud"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"Mensaje" : "Clinica Creada"})
}

func (h *ClinicaHandler) EliminarClinica(c *gin.Context) {

	var inputClinica models.Clinica

	if err := c.ShouldBindJSON(&inputClinica); err != nil {
		c.JSON(http.StatusBadRequest , gin.H{"error" : "sintaxis invalida"})
		return
	}
	
	clinica := &models.Clinica{
		IDClinica: inputClinica.IDClinica,
		Nombre: inputClinica.Nombre,
	}
	err := h.s.EliminarClinica(clinica)

	if err != nil {
		c.JSON(http.StatusConflict, gin.H{"error" : "Clinica no encontrada"})
	}

	c.JSON(http.StatusOK, gin.H{"Mensaje" : "Clinica eliminada"})
}

func (h  *ClinicaHandler) ActualizarClinica(c *gin.Context) {

	var inputClinica models.Clinica

	if err := c.ShouldBindJSON(&inputClinica); err != nil {
		c.JSON(http.StatusBadRequest , gin.H{"error" : "sintaxis invalida"})
		return
	}
	
	clinica := &models.Clinica{
		IDClinica: inputClinica.IDClinica,
		Nombre: inputClinica.Nombre,
	}

	err := h.s.ActualizarClinica(clinica)

	if err != nil {
		c.JSON(http.StatusConflict, gin.H{"error" : "Clinica no encontrada"})
	}

	c.JSON(http.StatusOK, gin.H{"Mensaje" : "Clinica actualizada"})

}

func (h *ClinicaHandler) ObtenerClinica(c *gin.Context) {

	var inputClinica models.Clinica

	if err := c.ShouldBindJSON(&inputClinica); err != nil {
		c.JSON(http.StatusBadRequest , gin.H{"error" : "sintaxis invalida"})
		return
	}

	clinica := &models.Clinica{
		IDClinica: inputClinica.IDClinica,
		Nombre: inputClinica.Nombre,
	}

	clinicaObtenida, err := h.s.BuscarClinica(clinica)

	if err != nil{
		c.JSON(http.StatusNotFound, gin.H{"error": "No se obtuvo informacion"})
		return
	}

	c.JSON(http.StatusOK, clinicaObtenida)
	
}

func (h *ClinicaHandler) ObtenerClinicas(c *gin.Context) {

	listaClinicas, err := h.s.ListarClinica()

	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error" : "Sin contenido"})
	}
	c.JSON(http.StatusOK, listaClinicas)
	
}



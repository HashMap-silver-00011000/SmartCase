package handlers

import (
	"backend/internal/models"
	"backend/internal/service"
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type SedeHandler struct {
	s *service.SedeService
}

func NewSedeHandler(s *service.SedeService) *SedeHandler {
	return &SedeHandler{s: s}
}

type requestSede struct {

	IDClinica uuid.UUID `json:"id_clinica"`
	Nombre    string    `json:"nombre"`

}

func (h *SedeHandler) CrearSede(c *gin.Context) {
	var inputSede requestSede

	if err := c.ShouldBindJSON(&inputSede); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "sintaxis invalida"})
		return
	}

	if inputSede.IDClinica == uuid.Nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "id_clinica requerido"})
		return
	}

	sede := &models.Sede{
		IDSede:    uuid.New(),
		IDClinica: inputSede.IDClinica,
		Nombre:    inputSede.Nombre,
	}

	err := h.s.CrearSede(sede)

	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Rechazo solicitud"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"Mensaje": "Sede Creada"})
}

func (h *SedeHandler) EliminarSede(c *gin.Context) {

	var inputSede models.Sede
	
	if err := c.ShouldBindJSON(&inputSede); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "sintaxis invalida"})
		return
	}

	log.Printf("%+v",  inputSede)

	sede := &models.Sede{
		IDSede: inputSede.IDSede,
	}
	err := h.s.EliminarSede(sede)

	if err != nil {
		c.JSON(http.StatusConflict, gin.H{"error": "Sede no encontrada"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"Mensaje": "Sede eliminada"})
}

func (h *SedeHandler) ActualizarSede(c *gin.Context) {

	var inputSede models.Sede

	if err := c.ShouldBindJSON(&inputSede); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "sintaxis invalida"})
		return
	}

	sede := &models.Sede{
		IDSede: inputSede.IDSede,
		Nombre: inputSede.Nombre,
	}

	log.Printf("%+v" , inputSede)
	err := h.s.ActualizarSede(sede)

	if err != nil {
		c.JSON(http.StatusConflict, gin.H{"error": "sede no encontrada"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"Mensaje": "sede actualizada"})
}

func (h *SedeHandler) ObtenerSede(c *gin.Context) {

	var inputSede models.Sede

	if err := c.ShouldBindJSON(&inputSede); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "sintaxis invalida"})
		return
	}

	sede := &models.Sede{
		IDSede: inputSede.IDSede,
	}

	sedeObtenida, err := h.s.BuscarSede(sede)

	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "No se obtuvo informacion"})
		return
	}

	c.JSON(http.StatusOK, sedeObtenida)
}

func (h *SedeHandler) ObtenerSedes(c *gin.Context) {

	idClinicaStr := c.Query("id_clinica")
	if idClinicaStr == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "id_clinica requerido"})
		return
	}

	idClinica, err := uuid.Parse(idClinicaStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "id_clinica invalido"})
		return
	}

	listaSedes, err := h.s.ListarSedesPorClinica(idClinica)

	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Sin contenido"})
		return
	}
	c.JSON(http.StatusOK, listaSedes)
}

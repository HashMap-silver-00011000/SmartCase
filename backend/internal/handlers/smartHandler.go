package handlers

import (
	"backend/internal/models"
	"backend/internal/service"
	"net/http"

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
		c.JSON(http.StatusBadRequest, gin.H{"error" : "sintaxis invalida"})
		return
	}

	smart := &models.SmartCase{
		IDCaja : uuid.New(),
		EstadoSolenoide: inputSmart.EstadoSolenoide,
		Organo: inputSmart.Organo,
	}

	err := h.s.CrearSmart(smart)

	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error" : "Rechazo solicitud"})//Evitar que la caja este en dos viajes
		return
	}

	c.JSON(http.StatusCreated, gin.H{"Mensaje" : "Caja Creada"})
}



func (h *SmartHandler) BuscarSmartCase(c *gin.Context) {
	//el ID de la URL
	idParam := c.Param("id")
	
	//Validar que sea un UUID real
	idUUID, err := uuid.Parse(idParam)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID de caja inválido o mal formado"})
		return
	}

	smartBuscar := &models.SmartCase{
		IDCaja: idUUID,
	}

	smartEncontrado, err := h.s.BuscarSmartCase(smartBuscar)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "No se encontró la caja solicitada"})
		return
	}

	c.JSON(http.StatusOK, smartEncontrado)
}


func (h *SmartHandler) ListarSmartCase(c *gin.Context) {
	
	lista, err := h.s.ListarSmartCase()
	
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error interno al obtener la lista de cajas"})
		return
	}

	c.JSON(http.StatusOK, lista)
}


func (h *SmartHandler) ActualizarSmartCase(c *gin.Context) {
	
	idParam := c.Param("id")
	idUUID, err := uuid.Parse(idParam)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID de caja inválido"})
		return
	}

	var inputSmart requestSmart
	if err := c.ShouldBindJSON(&inputSmart); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "sintaxis invalida en el cuerpo JSON"})
		return
	}

	smartActualizar := &models.SmartCase{
		IDCaja:          idUUID,
		EstadoSolenoide: inputSmart.EstadoSolenoide,
		Organo:          inputSmart.Organo,
	}

	err = h.s.ActualizarSmartCase(smartActualizar)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "No se pudo actualizar la caja"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"Mensaje": "Caja actualizada correctamente"})
}


func (h *SmartHandler) EliminarSmartCase(c *gin.Context) {

	idParam := c.Param("id")
	idUUID, err := uuid.Parse(idParam)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID de caja inválido"})
		return
	}

	smartEliminar := &models.SmartCase{
		IDCaja: idUUID,
	}

	err = h.s.EliminarSmartCase(smartEliminar)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "No se pudo eliminar la caja"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"Mensaje": "Caja eliminada correctamente"})
}

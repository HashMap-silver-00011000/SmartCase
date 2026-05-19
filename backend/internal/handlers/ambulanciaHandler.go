package handlers

import (
	"net/http"

	"backend/internal/models"
	"backend/internal/service"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type AmbulanciaHandler struct {
	s *service.AmbulanciaService
}

func NewAmbulanciaHandler(s *service.AmbulanciaService) *AmbulanciaHandler {
	return &AmbulanciaHandler{s: s}
}


type requestAmbulancia struct {
	Placa string `json:"placa"`
	Tipo  string `json:"tipo"`
}


func (h *AmbulanciaHandler) CrearAmbulancia(c *gin.Context) {
	var input requestAmbulancia

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Sintaxis inválida en el cuerpo JSON"})
		return
	}

	ambulancia := &models.Ambulancia{
		IDAmbulancia: uuid.New(),
		Placa:        input.Placa,
		Tipo:         input.Tipo,
	}

	err := h.s.CrearAmbulancia(ambulancia)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "No se pudo registrar la ambulancia"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"mensaje": "Ambulancia creada correctamente"})
}

func (h *AmbulanciaHandler) BuscarAmbulancia(c *gin.Context) {
	placaParam := c.Param("placa")

	if placaParam == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "La placa es requerida en la URL"})
		return
	}

	ambulanciaBuscar := &models.Ambulancia{
		Placa: placaParam,
	}

	ambulanciaEncontrada, err := h.s.BuscarAmbulancia(ambulanciaBuscar)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "No se encontró ninguna ambulancia con la placa proporcionada"})
		return
	}

	c.JSON(http.StatusOK, ambulanciaEncontrada)
}


func (h *AmbulanciaHandler) ListarAmbulancias(c *gin.Context) {

	ambulancias, err := h.s.ListarAmbulancias()

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error interno al obtener la lista de ambulancias"})
		return
	}
	c.JSON(http.StatusOK, ambulancias)
}

func (h *AmbulanciaHandler) ActualizarAmbulancia(c *gin.Context) {
	idParam := c.Param("id")
	idUUID, err := uuid.Parse(idParam)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID de ambulancia inválido o mal formado"})
		return
	}

	var input requestAmbulancia
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Sintaxis inválida en el cuerpo JSON"})
		return
	}

	ambulanciaActualizar := &models.Ambulancia{
		IDAmbulancia: idUUID,
		Placa:        input.Placa,
		Tipo:         input.Tipo,
	}

	err = h.s.ActualizarAmbulancia(ambulanciaActualizar)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "No se pudo actualizar la ambulancia"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"mensaje": "Ambulancia actualizada correctamente"})
}

func (h *AmbulanciaHandler) EliminarAmbulancia(c *gin.Context) {
	idParam := c.Param("id")
	idUUID, err := uuid.Parse(idParam)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID de ambulancia inválido o mal formado"})
		return
	}

	ambulanciaEliminar := &models.Ambulancia{
		IDAmbulancia: idUUID,
	}

	err = h.s.EliminarAmbulancia(ambulanciaEliminar)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "No se pudo eliminar la ambulancia"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"mensaje": "Ambulancia eliminada correctamente"})
}
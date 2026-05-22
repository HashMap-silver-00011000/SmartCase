package handlers

import (
	"backend/internal/repository"
	"net/http"

	"github.com/gin-gonic/gin"
)

type TelemetriaHandler struct {
	repo *repository.TelemetriaRepository
}

func NewTelemetriaHandler(repo *repository.TelemetriaRepository) *TelemetriaHandler {
	return &TelemetriaHandler{repo: repo}
}

// ListarPorViaje GET ?id_viaje=uuid
func (h *TelemetriaHandler) ListarPorViaje(c *gin.Context) {
	idViaje := c.Query("id_viaje")
	if idViaje == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "id_viaje es requerido"})
		return
	}

	lista, err := h.repo.ListarTelemetriaPorViaje(idViaje)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "No se pudo listar telemetría"})
		return
	}

	respuesta := []interface{}{}
	if lista != nil {
		for _, t := range *lista {
			respuesta = append(respuesta, t)
		}
	}
	c.JSON(http.StatusOK, respuesta)
}

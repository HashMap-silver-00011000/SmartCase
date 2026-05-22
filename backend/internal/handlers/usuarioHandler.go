package handlers

import (
	"backend/internal/service"
	"net/http"

	"github.com/gin-gonic/gin"
)

type UsuarioHandler struct {
	s *service.UsuarioService
}

func NewUsuarioHandler(s *service.UsuarioService) *UsuarioHandler {
	return &UsuarioHandler{s: s}
}

func (h *UsuarioHandler) ListarConductores(c *gin.Context) {
	lista, err := h.s.ListarConductores()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error al obtener conductores"})
		return
	}
	if lista == nil {
		c.JSON(http.StatusOK, []interface{}{})
		return
	}
	c.JSON(http.StatusOK, lista)
}

func (h *UsuarioHandler) ListarReceptores(c *gin.Context) {
	lista, err := h.s.ListarReceptores()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error al obtener receptores"})
		return
	}
	if lista == nil {
		c.JSON(http.StatusOK, []interface{}{})
		return
	}
	c.JSON(http.StatusOK, lista)
}

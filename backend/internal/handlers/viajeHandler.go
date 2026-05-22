package handlers

import (
	"backend/internal/models"
	"backend/internal/service"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type ViajeHandler struct {
	s *service.ViajeService
}

func NewViajeHandler(s *service.ViajeService) *ViajeHandler{
	return &ViajeHandler{s:s}
}

type RequestViaje struct {
	IDCaja              uuid.UUID `json:"id_caja" binding:"required"`
	IDUsuarioConductor  uuid.UUID `json:"id_usuario_conductor" binding:"required"`
	IDUsuarioReceptor   uuid.UUID `json:"id_usuario_receptor" binding:"required"`
	IDSedeOrigen        uuid.UUID `json:"id_sede_origen" binding:"required"`
	IDSedeDestino       uuid.UUID `json:"id_sede_destino" binding:"required"`
	IDAmbulancia        uuid.UUID `json:"id_ambulancia" binding:"required"`
	EstadoViaje         *string   `json:"estado_viaje,omitempty"`
}

func (h *ViajeHandler) CrearViaje(c *gin.Context) {

	var request RequestViaje

	if  err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error" : "Sintaxis invalida"})
		return
	}

	viaje := &models.Viaje{
		IDViaje:             uuid.New(),
		IDCaja:              request.IDCaja,
		IDUsuarioConductor:  request.IDUsuarioConductor,
		IDUsuarioReceptor:   request.IDUsuarioReceptor,
		IDSedeOrigen:        request.IDSedeOrigen,
		IDSedeDestino:       request.IDSedeDestino,
		IDAmbulancia:        request.IDAmbulancia,
		FechaInicio:         time.Now(),
		FechaLlegada:        nil,
		EstadoViaje:         request.EstadoViaje,
	}

	err := h.s.CrearViaje(viaje)

	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error" : "Error al crear viaje"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"Mensaje": "Viaje Creado"})

}

func (h *ViajeHandler) ListarPorEstado(c *gin.Context) {
	estado := c.Query("estado")
	if estado == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Query 'estado' es requerido"})
		return
	}

	viaje := &models.Viaje{
		EstadoViaje: &estado,
	}

	viajeEstado, err := h.s.ListarPorEstado(viaje)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Error al obtener viajes por estado"})
		return
	}

	respuesta := []models.Viaje{}
	if viajeEstado != nil {
		respuesta = *viajeEstado
	}
	c.JSON(http.StatusOK, respuesta)
}

func (h *ViajeHandler) ListarPorReceptor(c *gin.Context) {
	idRaw, ok := c.Get("id_usuario")
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Sesion invalida"})
		return
	}

	idStr, ok := idRaw.(string)
	if !ok || idStr == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "ID de usuario no disponible"})
		return
	}

	idUUID, err := uuid.Parse(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID de usuario invalido"})
		return
	}

	lista, err := h.s.ListarPorReceptor(idUUID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error al obtener viajes del receptor"})
		return
	}

	respuesta := []models.Viaje{}
	if lista != nil {
		respuesta = *lista
	}
	c.JSON(http.StatusOK, respuesta)
}



func (h *ViajeHandler) ListarPorUsuario(c *gin.Context) {
	idRaw, ok := c.Get("id_usuario")
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Sesion invalida"})
		return
	}

	idStr, ok := idRaw.(string)
	if !ok || idStr == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "ID de usuario no disponible"})
		return
	}

	idUUID, err := uuid.Parse(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID de usuario invalido"})
		return
	}

	lista, err := h.s.ListarPorUsuario(idUUID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error al obtener viajes del conductor"})
		return
	}

	respuesta := []models.Viaje{}
	if lista != nil {
		respuesta = *lista
	}
	c.JSON(http.StatusOK, respuesta)
}
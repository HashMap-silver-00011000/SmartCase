package websockets

import (
	"backend/internal/models"
	"backend/internal/repository"
	"encoding/json"
	"log"
	"time"

	"github.com/google/uuid"
)

type Hub struct {
	Broadcast  chan models.Telemetria
	Unregister chan *Client
	Register   chan *Client
	Clients    map[*Client]bool
	telemetria *repository.TelemetriaRepository
}

func NewHub(telemetriaRepo *repository.TelemetriaRepository) *Hub {
	return &Hub{
		Broadcast:  make(chan models.Telemetria),
		Register:   make(chan *Client),
		Unregister: make(chan *Client),
		Clients:    make(map[*Client]bool),
		telemetria: telemetriaRepo,
	}
}

func (h *Hub) Run() {
	for {
		select {
		case client := <-h.Register:
			h.Clients[client] = true

		case client := <-h.Unregister:
			if _, ok := h.Clients[client]; ok {
				delete(h.Clients, client)
				close(client.send)
			}

		case telemetria := <-h.Broadcast:
			h.prepareTelemetria(&telemetria)

			if h.telemetria != nil {
				if err := h.telemetria.GuardarTelemetria(&telemetria); err != nil {
					log.Println("Error guardando telemetría en BD:", err)
					continue
				}
			}

			mensajeBytes, err := json.Marshal(telemetria)
			if err != nil {
				log.Println("Error serializando telemetría:", err)
				continue
			}

			for client := range h.Clients {
				if client.ViajeID != telemetria.IDViaje.String() {
					continue
				}
				if client.Rol == "coductor" {
					continue
				}
				select {
				case client.send <- mensajeBytes:
				default:
					close(client.send)
					delete(h.Clients, client)
				}
			}
		}
	}
}

func (h *Hub) prepareTelemetria(t *models.Telemetria) {
	if t.IDTelemetria == uuid.Nil {
		t.IDTelemetria = uuid.New()
	}
	if t.RegistradoEn.IsZero() {
		t.RegistradoEn = time.Now().UTC()
	}
}

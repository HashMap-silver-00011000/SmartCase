package websockets

import (
	"backend/internal/models"
	"encoding/json"
	"log"

	"github.com/shopspring/decimal"
)

type Hub struct {

	Broadcast chan models.Telemetria

	Unregister chan *Client

	Register chan *Client

	Clients map[*Client]bool

}

func NewHub() *Hub {
	return &Hub{
		Broadcast:  make(chan models.Telemetria),
		Register:   make(chan *Client),
		Unregister: make(chan *Client),
		Clients:    make(map[*Client]bool),
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
                close(client.send) // Destruye el writePump de ese cliente
            }
            
        // BLOQUE DE TELEMETRÍA
        case telemetria := <-h.Broadcast:
            
            // ---------------------------------------------------------
            //Umbral Temperatura Ambiente
            // umbralTemperatura := decimal.NewFromFloat(38.0)
            // if telemetria.TempAmbiente .GreaterThan(umbralTemperatura) {
            //     log.Println("¡ALERTA TÉRMICA DETECTADA!")
            // }
            // ---------------------------------------------------------
            //Umbral Temperatura Interna
            umbralTemperaturaInterna := decimal.NewFromFloat(20.0)
            if telemetria.TemperaturaInterna.GreaterThan(umbralTemperaturaInterna) {
                log.Println("¡ALERTA TÉRMICA INTERNA DETECTADA!")
            }

            // ---------------------------------------------------------
            //Umbral gOLPE 
            umbralGolpe := decimal.NewFromFloat(28.0)
            if telemetria.FuerzaGImpacto.GreaterThan(umbralGolpe) {
                log.Println("Golpe")
            }


            // ---------------------------------------------------------
            // PREPARACIÓN PARA RED (Marshal)
            // ---------------------------------------------------------

            mensajeBytes, err := json.Marshal(telemetria)
            if err != nil {
                log.Println("Error serializando telemetría:", err)
                continue // Ignora el error y sigue esperando el próximo dato
            }

            // ---------------------------------------------------------
            // Repartimos el JSON en bytes a todos los clientes conectados.
			for client := range h.Clients {
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
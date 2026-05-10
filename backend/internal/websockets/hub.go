package websockets

import (
	"backend/internal/models"
	"encoding/json"
	"log"
)

type Hub struct {

	Broadcast chan models.Telemetria

	Unregister chan *Client

	Register chan *Client

	Clients map[*Client]bool

}

func newHub() *Hub {
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
            // A. LÓGICA DE NEGOCIO (El Servidor es Inteligente)
            // ---------------------------------------------------------
            // Aquí el Hub "ve" los datos reales. Puedes evaluar umbrales:
            // if telemetria.Temperatura > 38.0 {
            //     log.Println("¡ALERTA TÉRMICA DETECTADA!")
            //     // Insertar en base de datos, enviar correo, etc.
            // }

            // ---------------------------------------------------------
            // B. PREPARACIÓN PARA RED (Marshal)
            // ---------------------------------------------------------
            // Para poder enviar esta información por el cable de red hacia los 
            // navegadores web (writePump), debemos volver a convertir el objeto Go
            // en un paquete de bytes (JSON).
            mensajeBytes, err := json.Marshal(telemetria)
            if err != nil {
                log.Println("Error serializando telemetría:", err)
                continue // Ignora el error y sigue esperando el próximo dato
            }

            // ---------------------------------------------------------
            // C. DISTRIBUCIÓN (El Megáfono)
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
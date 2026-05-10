package handlers

import (
	"backend/internal/websockets"
	"log"

	"github.com/gin-gonic/gin"
)

// WsHandler es el manejador compatible con Gin. 
// Recibe el hub como argumento para poder inyectarlo.
func WsHandler(hub *websockets.Hub) gin.HandlerFunc {
	return func(c *gin.Context) {
		// 1. Upgrade de la conexión usando el Writer y Request de Gin
		conn, err := websockets.Upgrader.Upgrade(c.Writer, c.Request, nil)
		if err != nil {
			log.Printf("Error al convertir a WebSocket: %v", err)
			return
		}

		// 2. Crear el nuevo cliente
		client := websockets.NewClient(hub, conn)

		// 3. Registrar en el Hub
		hub.Register <- client

		// 4. Iniciar hilos de lectura y escritura
		go client.WritePump()
		go client.ReadPump()
	}
}
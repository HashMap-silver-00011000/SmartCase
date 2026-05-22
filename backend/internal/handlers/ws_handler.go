
package handlers

import (
    "backend/internal/websockets"
    "log"
    "net/http"

    "github.com/gin-gonic/gin"
)

func WsHandler(hub *websockets.Hub) gin.HandlerFunc {
return func(c *gin.Context) {

        viajeID := c.Query("id_viaje")
        
        if viajeID == "" {
            log.Println("Conexión rechazada: falta id_viaje en la URL")
            c.AbortWithStatusJSON(http.StatusBadRequest, gin.H{"error": "id_viaje es requerido"})
            return
        }
        rol := "desconocido"
        if rolInterface, existe := c.Get("rol"); existe {
            if r, ok := rolInterface.(string); ok && r != "" {
                rol = r
            }
        }

        conn, err := websockets.Upgrader.Upgrade(c.Writer, c.Request, nil)
        if err != nil {
            log.Printf("Error al convertir a WebSocket: %v", err)
            return
        }

        client := websockets.NewClient(hub, conn, viajeID, rol)
        log.Printf("WS conectado rol=%s viaje=%s", rol, viajeID)
        hub.Register <- client

        go client.WritePump()
        go client.ReadPump()
    }
}
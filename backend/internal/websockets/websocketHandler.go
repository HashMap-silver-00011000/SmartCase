package websockets

import (
	"net/http"

	"backend/internal/models"
	"fmt"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{

	ReadBufferSize:  1024, // Tamaño del balde de lectura
	WriteBufferSize: 1024, // Tamaño del balde de escritura

	//Permitir que cualquier  cliente se conecte
	CheckOrigin: func(r *http.Request) bool { return true },
}

// Esta función se ejecuta cada vez que ALGUIEN intenta conectarse al mapa
func serveWs(hub *Hub, c *gin.Context) {
    // 1. Ascendemos la petición HTTP a un WebSocket persistente
    conn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
    if err != nil {
        fmt.Println("Error al conectar:", err)
        return
    }

    // 2. Creamos la estructura que representa a esta persona
    cliente := &Client{
        hub:  hub,
        conn: conn,
        send: make(chan models.Telemetria, 256), // Creamos su canal personal con un pequeño buffer
    }

    // 3. Lo registramos en el Hub de forma segura (usando el canal, no el map directamente)
    cliente.hub.register <- cliente

    // 4. ¡Lanzamos las dos Goroutines independientes!
    // Usamos 'go' para que se ejecuten en el fondo
    go cliente.writePump() // Escucha al Hub y le escribe al usuario
    go cliente.readPump()  // Escucha al usuario y le escribe al Hub
    
    // Al llegar aquí, la función HTTP original termina, pero la conexión 
    // sigue viva y manejada por las dos goroutines en el fondo.
}


package websockets

import (
	"encoding/json"
	"log"
	"net/http"
	"time"

	"github.com/gorilla/websocket"
)

const (
	pongWait   = 120 * time.Second
	writeWait  = 15 * time.Second
	pingPeriod = 50 * time.Second
)

var Upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		return true
	},
}

type Client struct {
	conn    *websocket.Conn
	send    chan []byte
	hub     *Hub
	ViajeID string
	Rol     string
}

func NewClient(hub *Hub, conn *websocket.Conn, viajeID, rol string) *Client {
	return &Client{
		hub:     hub,
		conn:    conn,
		send:    make(chan []byte, 256),
		ViajeID: viajeID,
		Rol:     rol,
	}
}

func ptrStr(s *string) string {
    if s == nil {
        return "<nil>"
    }
    return *s
}

func (c *Client) ReadPump() {
	defer func() {
		c.hub.Unregister <- c
		c.conn.Close()
	}()

	c.conn.SetReadLimit(8192)
	c.conn.SetReadDeadline(time.Now().Add(pongWait))
	c.conn.SetPongHandler(func(string) error {
		c.conn.SetReadDeadline(time.Now().Add(pongWait))
		return nil
	})

	for {
		messageType, payload, err := c.conn.ReadMessage()
		if err != nil {
			// 1005 (no status) y cierre normal son habituales al salir de la app.
			if websocket.IsUnexpectedCloseError(
				err,
				websocket.CloseNormalClosure,
				websocket.CloseGoingAway,
				websocket.CloseNoStatusReceived,
				websocket.CloseAbnormalClosure,
			) {
				log.Printf("WS cerrado (%s, viaje %s): %v", c.Rol, c.ViajeID, err)
			}
			break
		}

		c.conn.SetReadDeadline(time.Now().Add(pongWait))

		if messageType != websocket.TextMessage {
			continue
		}

		// Monitores (admin/receptor) solo mantienen la conexión abierta.
		if c.Rol != "coductor" {
			continue
		}

		var input TelemetriaWSInput
		if err := json.Unmarshal(payload, &input); err != nil {
			log.Printf("JSON inválido (%s): %v · %s", c.Rol, err, string(payload))
			continue
		}
		//Trabbajo codigo/ respuesta3e3e3e33333ee3
		msg, err := input.ToModel(c.ViajeID)
		if err != nil {
			log.Printf("Telemetría rechazada: %v", err)
			continue
		}

		c.hub.Broadcast <- msg
	}
}

func (c *Client) WritePump() {
	ticker := time.NewTicker(pingPeriod)

	defer func() {
		ticker.Stop()
		c.conn.Close()
	}()

	for {
		select {
		case message, ok := <-c.send:
			c.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if !ok {
				c.conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}
			if err := c.conn.WriteMessage(websocket.TextMessage, message); err != nil {
				return
			}

		case <-ticker.C:
			c.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if err := c.conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}

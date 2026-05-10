package websockets

import (
	"backend/internal/models"
	"log"
	"net/http"
	"time"

	"github.com/gorilla/websocket"
)

const (

	//Tiempo de espera para el Pong
	pongWait = 60 * time.Second

	//Tiempo de espera escritura, pasa limite mata coneción con cliente
	writeWait  = 10 * time.Second

	//Tiempo espera para el ping
	pingWait = 54 * time.Second
)

var Upgrader = websocket.Upgrader{
	ReadBufferSize: 1024,
	WriteBufferSize: 1024,

	CheckOrigin: func(r *http.Request) bool {
		return true // Permitir conexiones desde cualquier origen (ESP32/Frontend)
	},
}

type Client struct {

	//CONNEC webSocket
	conn *websocket.Conn

	//Canal de envio de datos, tipo byte por datos  en TCP
	send chan []byte

	//Admin
	hub *Hub
	
}

func NewClient(hub *Hub, conn *websocket.Conn) *Client {
    return &Client{
		hub: hub,
        conn: conn,
        send: make(chan []byte, 256), // Buffer de 256 mensajes, para que el hub pueda meter mensajes
    }
}


func(c *Client) ReadPump() {

	defer func(){
		c.hub.Unregister <- c
		c.conn.Close()//cierra conexión TCP
	}()

	//Limites de seguridad
	c.conn.SetReadLimit(512)//si no se define, el cliente puede tumbar el servidor con datos grandes
	c.conn.SetReadDeadline(time.Now().Add(pongWait))
	c.conn.SetPongHandler(func(string) error { 
		c.conn.SetReadDeadline(time.Now().Add(pongWait));
	     return nil 
	})

	//Loop de lectura infinito, se rompe unicamente con un error
	for {
		var msg models.Telemetria
		err :=  c.conn.ReadJSON(&msg)

		if err != nil {
			log.Print(err)
			break
		}

	//Enviar datos al hub
		c.hub.Broadcast <- msg		

	}

}

func (c *Client) WritePump(){
	 
	//El ticker se utiliza para enviar un latido
	ticker :=  time.NewTicker(pingWait)

	defer func() {
		ticker.Stop()
		c.conn.Close()
	}()

	for {
		//Select por si es ticker o write

		select{
		case message, ok :=  <- c.send:
			c.conn.SetWriteDeadline(time.Now().Add(writeWait))
			
			if !ok {
				//Avisar que voy a cerrar la conexión para que el cliente pueda limpiar memoria
				//Frame de cierre puede llevar informacion en el payload, por eso el byte
				c.conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}
			//Abrir flujo de escritura hacia el cliente
			// // escritor 'w' y le ponemos la etiqueta "Es Texto".
			// w, err := c.conn.NextWriter(websocket.TextMessage)

			// if err != nil{
			// 	log.Print(err)
			// 	return
			// }
			// //Escribir mensaje en la red
			// w.Write(mensaje)

			// //batching
			// //Mensajes acumulados en la RAM
			// n := len(c.send)

			// for i :=  0; i < n ; i++{
			// 	w.Write(newLine)
			// 	w.Write(<-c.send)
			// }

			// //Mandar todo si no hay error

			// if err := w.Close() ; err != nil{
			// 	log.Print(err)
			// 	return
			// }

			// ==========================================
            // VERSIÓN IOT (Simple y Directa)
            // Cero saltos de línea, cero agrupamiento.
            // Mandamos exactamente el JSON que llegó del Hub.
            // ==========================================
            err := c.conn.WriteMessage(websocket.TextMessage, message)
            
            if err != nil {
                // Si hay error de red al escribir, matamos la conexión
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



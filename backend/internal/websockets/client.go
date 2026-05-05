package websockets

import (
	"github.com/gorilla/websocket"
	"backend/internal/models"
    "backend/internal/repository"
    "time"
    "log"

)


type Client struct {
    // Puntero al Hub central (dirección de memoria del director de tráfico)
    hub *Hub
    // Puntero a la conexión WebSocket real con el celular/navegador
    conn *websocket.Conn
    // Un canal (channel) personal para los mensajes que el Hub le quiere enviar a ESTE cliente
    send chan models.Telemetria

    telemetriaService *repository.TelemetriaRepository
}

//Uso del patron Pumps, dos goroutines por cliente conectado, lectura y escritura

//Constantes de tiempo
const (

	writeWait      = 10 * time.Second    // timeout para escrituras, Tiempo máximo permitido para escribir un mensaje en la red
	pongWait       = 60 * time.Second    // tiempo de espera por un Pong
	pingPeriod     = (pongWait * 9) / 10 // con qué frecuencia enviamos Ping
	
)



//Lectura en la red

func (c *Client) readPump() {

    // Si la función termina o falla, desconectamos al cliente del Hub y cerramos la conexión
    defer func () {
        c.hub.unregister <- c
        c.conn.Close()
    }()

    //Configurar el tiempo inicial
    c.conn.SetReadDeadline(time.Now().Add(pongWait))

    //Decirle a Gorilla que hacer cuando reciba el "Pong"
    c.conn.SetPongHandler(func(string) error { 
        c.conn.SetReadDeadline(time.Now().Add(pongWait))
        return nil 
    })

    //Bucle infinito

    for {
        var telemetria models.Telemetria
        
        err := c.conn.ReadJSON(&telemetria)
        if err != nil {
            // Si hay un error (ej. se acabó el tiempo límite o perdió señal), rompemos el bucle
            log.Printf("Error de lectura o cliente desconectado: %v", err)
            break
        }

        // Si recibimos una coordenada, ¡también reiniciamos el reloj para ser amables!
        c.conn.SetReadDeadline(time.Now().Add(pongWait))

        // Enviamos la coordenada al director de tráfico (Hub)
        c.hub.broadcast <- telemetria

        go c.telemetriaService.GuardarTelemetria(&telemetria)
    }

}

func (c *Client) writePump() {
    // Creamos nuestro "metrónomo" que sonará cada 54 segundos
    ticker := time.NewTicker(pingPeriod)
    
    // Al salir, limpiamos el ticker y cerramos la conexión
    defer func() {
        ticker.Stop()
        c.conn.Close()
    }()

    for {
        // Usamos SELECT para escuchar MÚLTIPLES canales al mismo tiempo
        select {
        
        // CASO A: El Hub nos envió una coordenada por nuestro canal personal
        case coordenada, ok := <-c.send:
            c.conn.SetWriteDeadline(time.Now().Add(writeWait)) // Damos 10s para enviarlo
            if !ok {
                // Si el Hub cerró el canal, significa que debemos desconectar a este cliente
                c.conn.WriteMessage(websocket.CloseMessage, []byte{})
                return
            }

            // Enviamos el JSON al celular/navegador del usuario
            err := c.conn.WriteJSON(coordenada)
            if err != nil {
                return // Si falla la red, salimos
            }

        // CASO B: ¡Sonó el metrónomo! (Pasaron 54 segundos)
        case <-ticker.C:
            c.conn.SetWriteDeadline(time.Now().Add(writeWait))
            
            // Enviamos el mensaje Ping oculto
            err := c.conn.WriteMessage(websocket.PingMessage, nil)
            if err != nil {
                return // Si no pudimos enviar el Ping, la conexión está muerta, salimos.
            }
        }
    }
}
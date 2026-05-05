package websockets

//Director  de operaciones: cada que un usuario se conecta abre su propio bucle for

import (
	"backend/internal/models"
	"fmt"
)


type Hub struct	{

	broadcast chan models.Telemetria
	clientes map[*Client]bool

	//conexiones nuevas
	register chan *Client

	//cierran la app
	unregister chan *Client
}

func (h Hub) Run(){
	for {
		//SELECT ELECCION DE CASOS PARA CONCURRENCIA
		select{
			//Alguien nuevo se conecta
		case cliente := <-h.register:
			h.clientes[cliente] = true 
			fmt.Println("Nuevo cliente")

			//cliente cerro la app
		case cliente := <- h.unregister:
			if _, existe := h.clientes[cliente]; existe {
                delete(h.clientes, cliente)
                fmt.Println("Cliente desconectado")
            }

			//El conductor envio nuevos datos de telemetria
		// case mensaje := <-h.broadcast:
		// 	for cliente := range h.clientes {

		// 	}

		
		}
	}
}
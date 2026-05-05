package websockets

type Message struct {
	Type    string `json:"type"`    // "chat", "system", "error"
	Payload string `json:"payload"` // contenido del mensaje
	From    string `json:"from"`    // ID del remitente
}
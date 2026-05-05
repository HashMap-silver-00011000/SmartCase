package models 

import (
	"github.com/shopspring/decimal"
	"github.com/google/uuid" 
	"time"
)


type Telemetria struct{

	IDtel  uuid.UUID 			`db:"id_telemetria"  json:"telemetria"`
    IDBus	uuid.UUID 			`db:"id_bus" 		 json:"id_bus"`
	Latitud	decimal.Decimal	 	`db:"latitud" 		 json:"lat"`
    Longitud decimal.Decimal 	`db:"longitud" 		 json:"long"`
    FechaHora  time.Time 		`db:"fecha_hora" 	 json:"fecha"`

}

package models 

import (
	"github.com/shopspring/decimal"
	"github.com/google/uuid" 

)


// Telemetria utiliza decimal.Decimal para latitud, longitud e impactos
type Telemetria struct {
	IDTelemetria       uuid.UUID       `db:"id_telemetria" json:"id_telemetria"`
	IDViaje            uuid.UUID       `db:"id_viaje" json:"id_viaje"`
	TemperaturaInterna decimal.Decimal        `db:"temperatura_interna" json:"temperatura_interna"`
	LatitudActual      decimal.Decimal `db:"latitud_actual" json:"latitud_actual"`   // Precisión para GPS
	LongitudActual     decimal.Decimal `db:"longitud_actual" json:"longitud_actual"` // Precisión para GPS
	FuerzaGImpacto     decimal.Decimal `db:"fuerza_g_impacto" json:"fuerza_g_impacto"` // Manejo preciso de impactos
	AlertaGenerada     *string         `db:"alerta_generada" json:"alerta_generada"`
}
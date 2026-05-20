package models

import (
	"time"

	"github.com/google/uuid"
	"github.com/shopspring/decimal"
)

// Telemetria utiliza decimal.Decimal para valores numéricos de alta precisión
type Telemetria struct {
    IDTelemetria        uuid.UUID       `db:"id_telemetria" json:"id_telemetria"`
    IDViaje             uuid.UUID       `db:"id_viaje" json:"id_viaje"`
    TemperaturaInterna  decimal.Decimal `db:"temperatura_interna" json:"temperatura_interna"`
    LatitudActual       decimal.Decimal `db:"latitud_actual" json:"latitud_actual"`
    LongitudActual      decimal.Decimal `db:"longitud_actual" json:"longitud_actual"`
    FuerzaGImpacto      decimal.Decimal `db:"fuerza_g_impacto" json:"fuerza_g_impacto"`
    AlertaGenerada      *string         `db:"alerta_generada" json:"alerta_generada"`
    TemperaturaAmbiente decimal.Decimal `db:"temperatura_ambiente" json:"temperatura_ambiente"`
    Humedad             decimal.Decimal `db:"humedad" json:"humedad"`
    Lux                 decimal.Decimal `db:"lux" json:"lux"`
    Altitud             decimal.Decimal `db:"altitud" json:"altitud"`
    RegistradoEn        time.Time       `db:"registrado_en" json:"registrado_en"`
    DesdeBluetooth      bool            `db:"desde_bluetooth" json:"desde_bluetooth"`
}
package websockets

import (
	"backend/internal/models"
	"time"

	"github.com/google/uuid"
	"github.com/shopspring/decimal"
)

// TelemetriaWSInput JSON enviado por la app Flutter (números nativos).
type TelemetriaWSInput struct {
	IDTelemetria        string   `json:"id_telemetria"`
	IDViaje             string   `json:"id_viaje"`
	TemperaturaInterna  float64  `json:"temperatura_interna"`
	LatitudActual       float64  `json:"latitud_actual"`
	LongitudActual      float64  `json:"longitud_actual"`
	FuerzaGImpacto      float64  `json:"fuerza_g_impacto"`
	AlertaGenerada      *string  `json:"alerta_generada"`
	TemperaturaAmbiente *float64 `json:"temperatura_ambiente"`
	Humedad             *float64 `json:"humedad"`
	Lux                 *float64 `json:"lux"`
	Altitud             *float64 `json:"altitud"`
	RegistradoEn        string   `json:"registrado_en"`
	DesdeBluetooth      bool     `json:"desde_bluetooth"`
}

func (in *TelemetriaWSInput) ToModel(viajeFallback string) (models.Telemetria, error) {
	var t models.Telemetria

	if in.IDTelemetria != "" {
		id, err := uuid.Parse(in.IDTelemetria)
		if err != nil {
			return t, err
		}
		t.IDTelemetria = id
	}

	viajeStr := in.IDViaje
	if viajeStr == "" {
		viajeStr = viajeFallback
	}
	viajeID, err := uuid.Parse(viajeStr)
	if err != nil {
		return t, err
	}
	t.IDViaje = viajeID

	t.TemperaturaInterna = decimal.NewFromFloat(in.TemperaturaInterna)
	t.LatitudActual = decimal.NewFromFloat(in.LatitudActual)
	t.LongitudActual = decimal.NewFromFloat(in.LongitudActual)
	t.FuerzaGImpacto = decimal.NewFromFloat(in.FuerzaGImpacto)
	t.AlertaGenerada = in.AlertaGenerada

	if in.TemperaturaAmbiente != nil {
		t.TemperaturaAmbiente = decimal.NewFromFloat(*in.TemperaturaAmbiente)
	}
	if in.Humedad != nil {
		t.Humedad = decimal.NewFromFloat(*in.Humedad)
	}
	if in.Lux != nil {
		t.Lux = decimal.NewFromFloat(*in.Lux)
	}
	if in.Altitud != nil {
		t.Altitud = decimal.NewFromFloat(*in.Altitud)
	}

	if in.RegistradoEn != "" {
		if parsed, err := time.Parse(time.RFC3339, in.RegistradoEn); err == nil {
			t.RegistradoEn = parsed.UTC()
		} else {
			t.RegistradoEn = time.Now().UTC()
		}
	} else {
		t.RegistradoEn = time.Now().UTC()
	}

	t.DesdeBluetooth = in.DesdeBluetooth
	return t, nil
}

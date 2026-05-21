package repository

import (
	"log"

	"github.com/jmoiron/sqlx"
	"backend/internal/models"
)

type TelemetriaRepository struct {
	db *sqlx.DB
}

func NewTelemetriaRepository(db *sqlx.DB) *TelemetriaRepository {
	if db == nil {
		panic("No puedes crear un repositorio sin una base de datos")
	}
	return &TelemetriaRepository{db: db}
}

func (r *TelemetriaRepository) CrearTelemetria(telemetria *models.Telemetria) error {
	_, err := r.db.NamedExec(`INSERT INTO telemetria 
                            (id_telemetria, id_viaje, temperatura_interna, latitud_actual, longitud_actual, 
                             fuerza_g_impacto, alerta_generada, temperatura_ambiente, humedad, lux, altitud, 
                             registrado_en, desde_bluetooth) 
                            VALUES 
                            (:id_telemetria, :id_viaje, :temperatura_interna, :latitud_actual, :longitud_actual, 
                             :fuerza_g_impacto, :alerta_generada, :temperatura_ambiente, :humedad, :lux, :altitud, 
                             :registrado_en, :desde_bluetooth)`, telemetria)

	if err != nil {
		log.Printf("Error creating telemetria: %v", err)
	}
	return err
}

// GuardarTelemetria inserta o actualiza por id_telemetria (misma lectura en vivo del conductor).
func (r *TelemetriaRepository) GuardarTelemetria(telemetria *models.Telemetria) error {
	var existe bool
	err := r.db.Get(&existe, `SELECT EXISTS(SELECT 1 FROM telemetria WHERE id_telemetria = $1)`, telemetria.IDTelemetria)
	if err != nil {
		log.Printf("Error comprobando telemetria: %v", err)
		return err
	}
	if existe {
		return r.ActualizarTelemetria(telemetria)
	}
	return r.CrearTelemetria(telemetria)
}

func (r *TelemetriaRepository) BuscarTelemetria(telemetria *models.Telemetria) (*models.Telemetria, error) {
	var t models.Telemetria
	// Solicitar la información de la telemetría si existe el ID
	err := r.db.Get(&t, "SELECT * FROM telemetria WHERE id_telemetria = $1", telemetria.IDTelemetria)

	if err != nil {
		log.Print(err)
		return nil, err // retorna error si no encuentra nada (sql.ErrNoRows)
	}
	return &t, nil
}

func (r *TelemetriaRepository) ListarTelemetria() (*[]models.Telemetria, error) {
	var telemetrias []models.Telemetria

	err := r.db.Select(&telemetrias, "SELECT * FROM telemetria")

	if err != nil {
		log.Printf("Error al obtener la lista de telemetría: %v", err)
		return nil, err
	}
	return &telemetrias, nil
}

// 💡 Bonus: En tablas de telemetría, casi siempre necesitarás buscar por viaje
func (r *TelemetriaRepository) ListarTelemetriaPorViaje(idViaje string) (*[]models.Telemetria, error) {
	var telemetrias []models.Telemetria

	err := r.db.Select(&telemetrias, "SELECT * FROM telemetria WHERE id_viaje = $1 ORDER BY registrado_en ASC", idViaje)

	if err != nil {
		log.Printf("Error al obtener la telemetría del viaje %s: %v", idViaje, err)
		return nil, err
	}
	return &telemetrias, nil
}

func (r *TelemetriaRepository) EliminarTelemetria(telemetria *models.Telemetria) error {
	resultado, err := r.db.NamedExec(`DELETE FROM telemetria WHERE id_telemetria = :id_telemetria`, telemetria)

	if err != nil {
		log.Printf("Error al eliminar la telemetria: %v", err)
		return err
	}

	filasAfectadas, _ := resultado.RowsAffected()

	if filasAfectadas == 0 {
		// No hubo error de SQL, pero no encontró el registro
		log.Printf("No se encontró la telemetria con ID %s para eliminar", telemetria.IDTelemetria)
	}

	return nil
}

func (r *TelemetriaRepository) ActualizarTelemetria(telemetria *models.Telemetria) error {
	_, err := r.db.NamedExec(`UPDATE telemetria 
                              SET id_viaje = :id_viaje,
                                  temperatura_interna = :temperatura_interna,
                                  latitud_actual = :latitud_actual,
                                  longitud_actual = :longitud_actual,
                                  fuerza_g_impacto = :fuerza_g_impacto,
                                  alerta_generada = :alerta_generada,
                                  temperatura_ambiente = :temperatura_ambiente,
                                  humedad = :humedad,
                                  lux = :lux,
                                  altitud = :altitud,
                                  registrado_en = :registrado_en,
                                  desde_bluetooth = :desde_bluetooth
                              WHERE id_telemetria = :id_telemetria`, 
                              telemetria)

	if err != nil {
		log.Printf("Error actualizando telemetria: %v", err)
		return err
	}

	return nil
}



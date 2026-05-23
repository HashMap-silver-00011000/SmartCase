package repository

import (
	"log"

	"backend/internal/models"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
)


type ViajeRepository struct{
	db *sqlx.DB
}

func NewViajeCaseRepository(db *sqlx.DB) *ViajeRepository{

	if db == nil {
		panic("No puedes crear un viaje sin una base de datos")
	}
	return &ViajeRepository{db:db}
}

func (r *ViajeRepository) CrearViaje(viaje *models.Viaje) error {

	_, err := r.db.NamedExec(`INSERT INTO viaje (id_viaje, id_caja, id_usuario_conductor, id_usuario_receptor, id_sede_origen, id_sede_destino, id_ambulancia,
                                              fecha_inicio, fecha_llegada, estado_viaje, pin_entrega) VALUES (:id_viaje, :id_caja, :id_usuario_conductor, :id_usuario_receptor, :id_sede_origen, :id_sede_destino, :id_ambulancia,
                                              :fecha_inicio, :fecha_llegada, :estado_viaje, :pin_entrega)`, viaje)

    log.Printf("Error creating viaje: %v", err)
    return err

}


func (r *ViajeRepository) ObtenerViaje(viaje *models.Viaje) (*models.Viaje, error){
	
	var viajeR models.Viaje

	err := r.db.Get(&viajeR, "SELECT * FROM usuario WHERE id_viaje = $1", viaje.IDViaje)

	if err != nil {
		log.Printf("viaje no encontrado en la db: %v", err)
		return nil, err 
	}

	return &viajeR, nil

}

func (r *ViajeRepository) ListarPorEstado(viaje *models.ViajeConductor)(*[]models.ViajeConductor, error){

	var listaViaje []models.ViajeConductor

	err := r.db.Select(&listaViaje, `SELECT id_viaje, id_caja, id_usuario_conductor, id_usuario_receptor, id_sede_origen, id_sede_destino, id_ambulancia,
                                              fecha_inicio, fecha_llegada, estado_viaje
									FROM viaje WHERE estado_viaje = $1 ORDER BY fecha_inicio DESC`, viaje.EstadoViaje)

	if err != nil {
		log.Printf("Error en la consulta: %v", err)
		return nil, err
	}

	return &listaViaje, nil
}

func (r *ViajeRepository) ListarPorUsuario(id_usuario_conductor uuid.UUID)(*[]models.ViajeConductor, error){

	var listaViaje []models.ViajeConductor

	err := r.db.Select(&listaViaje, `SELECT id_viaje, id_caja, id_usuario_conductor, id_usuario_receptor, id_sede_origen, id_sede_destino, id_ambulancia,
                                              fecha_inicio, fecha_llegada, estado_viaje
									FROM viaje WHERE id_usuario_conductor = $1 ORDER BY fecha_inicio DESC`, id_usuario_conductor)

	if err != nil {
		log.Printf("Error en la consulta: %v", err)
		return nil, err
	}

	return &listaViaje, nil
}

func (r *ViajeRepository) ListarPorReceptor(idUsuarioReceptor uuid.UUID) (*[]models.Viaje, error) {
	var listaViaje []models.Viaje

	err := r.db.Select(&listaViaje, `SELECT id_viaje, id_caja, id_usuario_conductor, id_usuario_receptor, id_sede_origen, id_sede_destino, id_ambulancia,
                                              fecha_inicio, fecha_llegada, estado_viaje, pin_entrega
									FROM viaje WHERE id_usuario_receptor = $1 ORDER BY fecha_inicio DESC`, idUsuarioReceptor)

	if err != nil {
		log.Printf("Error en la consulta receptor: %v", err)
		return nil, err
	}

	return &listaViaje, nil
}

func (r *ViajeRepository) ActualizarEstadoViaje(viaje *models.Viaje)  error {

	_ ,err := r.db.NamedExec(`UPDATE viaje 
                          SET estado_viaje = :estado_viaje 
                          WHERE id_viaje = :id_viaje`,
		viaje)

	if err != nil {
        log.Printf("Error en la solicitud: %v", err)
        return err
    }


	return nil
}

func(r *ViajeRepository) ComprobarPin(pin *models.Viaje) (*models.Viaje, error){

	var viaje models.Viaje
	
	err := r.db.Get(&viaje, "SELECT * FROM viaje WHERE id_viaje = $1", pin.IDViaje)

	if err != nil {
    	log.Print(err)
		return nil, err // retorna error si no encuentra nada (sql.ErrNoRows)
	}
	return &viaje, nil

}
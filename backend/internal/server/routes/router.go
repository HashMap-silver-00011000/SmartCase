package routes

import (
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/jmoiron/sqlx"

	"backend/internal/handlers"
	"backend/internal/repository"
	"backend/internal/server/middleware"
	"backend/internal/service"
	"backend/internal/websockets"
)

func ConfigurarRutas(db *sqlx.DB, hub *websockets.Hub) *gin.Engine {

	r := gin.Default()

	// Configuración CORS estricta requerida para Sesiones/Cookies
	r.Use(cors.New(cors.Config{
		// frontend está en el puerto 3000, ponerlo explícitamente. "*" no funciona con credenciales.
		AllowOrigins:     []string{"http://localhost:3000"},
		AllowMethods:     []string{"POST", "GET", "OPTIONS", "PUT", "DELETE"},
		AllowHeaders:     []string{"Origin", "Content-Type"},
		AllowCredentials: true, // ¡CRÍTICO PARA SESIONES!
		MaxAge:           12 * time.Hour,
	}))

	// Inyecciones

	//Auth
	usuarioRepo := repository.NewUsuarioRepository(db)
	usuarioService := service.NewUsuarioService(usuarioRepo)
	authHandler := handlers.NewAuthHandler(usuarioService)

	//Clinica
	clinicaRepo := repository.NewClinicaRepository(db)
	clinicaService := service.NewClinicaService(clinicaRepo)
	clinicaHandler := handlers.NewClinicaHandler(clinicaService)

	//sede
	sedeRepo := repository.NewSedeRepository(db)
	sedeService := service.NewSedeService(sedeRepo)
	sedeHandler :=  handlers.NewSedeHandler(sedeService)

	//SmartCase
	caseRepo := repository.NewSmartCaseRepository(db)
	caseService := service.NewSedeService(caseRepo)
	caseHandler := handler.NewSedeHandler(caseService)

	// --- RUTAS PÚBLICAS (Login / Registro) ---
	api := r.Group("/api")
	{
		api.POST("/login", authHandler.Login)
		api.POST("/register", authHandler.Registro)
	}

	// --- ZONA PRIVADA (Requiere Sesión Activa) ---
	privadas := r.Group("/api/app")
	{
		// ZONA ADMIN
		panelAdmin := privadas.Group("/panel-admin")
		panelAdmin.Use(middleware.RequiereAuth("admin"))
		{
			panelClinica := panelAdmin.Group("/clinica") 
			{
				panelClinica.POST("/crear", clinicaHandler.CrearClinica)
				panelClinica.GET("/obtener", clinicaHandler.ObtenerClinica)
				panelClinica.GET("/lista", clinicaHandler.ObtenerClinicas)
				panelClinica.PUT("/actualizar", clinicaHandler.ActualizarClinica)
				panelClinica.DELETE("/borrar", clinicaHandler.EliminarClinica)

				panelSede := panelClinica.Group("/sede")
				{
					panelSede.POST("/crear", sedeHandler.CrearSede)
					panelSede.GET("/obtener",sedeHandler.ObtenerSede)
					panelSede.GET("/lista",sedeHandler.ObtenerSedes)
					panelSede.PUT("/actualizar",sedeHandler.ActualizarSede)
					panelSede.DELETE("/borrar", sedeHandler.EliminarSede)
				}
			}
			
		}
	}


	// wsGroup := r.Group("/api/ws")
	// wsGroup.Use(middleware.RequiereAuth())           // Debe estar logueado
	// wsGroup.Use(middleware.RequiereRol("conductor")) // SOLO para conductores
	// {
	// 	wsGroup.GET("/telemetria", handlers.WsHandler(hub))
	// }

	return r
}

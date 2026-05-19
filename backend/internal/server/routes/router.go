package routes

import (
	"strings"
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
		AllowOriginFunc: func(origin string) bool {
			if origin == "" {
				return true
			}
			if origin == "http://localhost:3000" {
				return true
			}
			return strings.HasPrefix(origin, "http://localhost:") ||
				strings.HasPrefix(origin, "http://127.0.0.1:")
		},
		AllowMethods:     []string{"POST", "GET", "OPTIONS", "PUT", "DELETE"},
		AllowHeaders:     []string{"Origin", "Content-Type"},
		AllowCredentials: true,
		MaxAge:           12 * time.Hour,
	}))

	// Inyecciones

	//Auth
	usuarioRepo := repository.NewUsuarioRepository(db)
	usuarioService := service.NewUsuarioService(usuarioRepo)
	authHandler := handlers.NewAuthHandler(usuarioService)
	usuarioHandler := handlers.NewUsuarioHandler(usuarioService)

	//Clinica
	clinicaRepo := repository.NewClinicaRepository(db)
	clinicaService := service.NewClinicaService(clinicaRepo)
	clinicaHandler := handlers.NewClinicaHandler(clinicaService)

	//sede
	sedeRepo := repository.NewSedeRepository(db)
	sedeService := service.NewSedeService(sedeRepo)
	sedeHandler := handlers.NewSedeHandler(sedeService)

	//Ambulancia
	ambulanciaRepo := repository.NewAmbulanciaRepository(db)
	ambulanciaService := service.NewAmbulanciaService(ambulanciaRepo)
	ambulanciaHandler := handlers.NewAmbulanciaHandler(ambulanciaService)

	//SmartCase
	smartRepo := repository.NewSmartCaseRepository(db)
	smartService := service.NewSmartService(smartRepo)
	smartHandler := handlers.NewSmartHandler(smartService)

	//Viaje
	viajeRepo := repository.NewViajeCaseRepository(db)
	viajeService := service.NewViajeService(viajeRepo)
	viajeHandler := handlers.NewViajeHandler(viajeService)

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
					panelSede.GET("/obtener", sedeHandler.ObtenerSede)
					panelSede.GET("/lista", sedeHandler.ObtenerSedes)
					panelSede.PUT("/actualizar", sedeHandler.ActualizarSede)
					panelSede.DELETE("/borrar", sedeHandler.EliminarSede)
				}
			}

			panelAmbulancia := panelAdmin.Group("/ambulancia")
			{
				panelAmbulancia.POST("/crear", ambulanciaHandler.CrearAmbulancia)
				panelAmbulancia.GET("/lista", ambulanciaHandler.ListarAmbulancias)
				panelAmbulancia.GET("/obtener/:placa", ambulanciaHandler.BuscarAmbulancia)
				panelAmbulancia.PUT("/actualizar/:id", ambulanciaHandler.ActualizarAmbulancia)
				panelAmbulancia.DELETE("/borrar/:id", ambulanciaHandler.EliminarAmbulancia)
			}

			panelSmartCase := panelAdmin.Group("/smartcase")
			{
				panelSmartCase.POST("/crear", smartHandler.CrearSmart)
				panelSmartCase.GET("/lista", smartHandler.ListarSmartCase)
				panelSmartCase.GET("/obtener/:id", smartHandler.BuscarSmartCase)
				panelSmartCase.PUT("/actualizar/:id", smartHandler.ActualizarSmartCase)
				panelSmartCase.DELETE("/borrar/:id", smartHandler.EliminarSmartCase)
			}

			panelViaje := panelAdmin.Group("/viaje")
			{
				panelViaje.POST("/crear", viajeHandler.CrearViaje)
			}

			panelUsuario := panelAdmin.Group("/usuario")
			{
				panelUsuario.GET("/conductores/lista", usuarioHandler.ListarConductores)
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

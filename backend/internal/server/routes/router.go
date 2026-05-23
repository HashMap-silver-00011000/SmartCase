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
			// 1. Acepta peticiones sin origen (Apps móviles nativas de Flutter)
			if origin == "" {
				return true
			}

			// 2. Acepta tus entornos de desarrollo web locales tradicionales
			if origin == "http://localhost:3000" || strings.HasPrefix(origin, "http://localhost:") || strings.HasPrefix(origin, "http://127.0.0.1:") {
				return true
			}

			// 3. NUEVO: Acepta cualquier origen que provenga de tu red local (192.168.X.X o 10.X.X.X)
			// Esto es vital por si ejecutas Flutter Web desde el navegador del celular apuntando a la IP de tu PC
			if strings.HasPrefix(origin, "http://192.168.") || strings.HasPrefix(origin, "http://10.") {
				return true
			}

			return false
		},
		AllowMethods: []string{"POST", "GET", "OPTIONS", "PUT", "DELETE"},
		// 4. AJUSTE CRÍTICO: Si usas autenticación o tokens personalizados, necesitas aceptar más cabeceras
		AllowHeaders:     []string{"Origin", "Content-Type", "Accept", "Authorization", "X-Requested-With"},
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

	//Telemetria
	telemetriaRepo := repository.NewTelemetriaRepository(db)
	telemetriaHandler := handlers.NewTelemetriaHandler(telemetriaRepo)

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
				panelViaje.GET("/viajes-estado", viajeHandler.ListarPorEstado)
				panelViaje.GET("/telemetria", telemetriaHandler.ListarPorViaje)
				panelViaje.GET("/tareas-viaje-telemetria", handlers.WsHandler(hub))
			}
		

			panelUsuario := panelAdmin.Group("/usuario")
			{
				panelUsuario.GET("/conductores/lista", usuarioHandler.ListarConductores)
				panelUsuario.GET("/receptores/lista", usuarioHandler.ListarReceptores)
			}
		}

		//ZONA CONDUCTORES

		panelConductor := privadas.Group("/conductor")
		panelConductor.Use(middleware.RequiereAuth("coductor"))
		{
			//Viaje
			panelViaje := panelConductor.Group("/viaje")
			{
				panelViaje.GET("/tareas-viaje", viajeHandler.ListarPorUsuario)
				panelViaje.GET("/tareas-viaje-telemetria", handlers.WsHandler(hub))
				panelViaje.PUT("/actualizar-estado-viaje", viajeHandler.ActualizarEstadoViaje)
				panelViaje.POST("/pin-desbloqueo", viajeHandler.ComprobarPin)
			}

		}

		//ZONA RECEPTORES

		panelMedico := privadas.Group("/medico")
		panelMedico.Use(middleware.RequiereAuth("receptor"))
		{
			//Viaje
			panelViaje := panelMedico.Group("/viaje")
			{
				panelViaje.GET("/tareas-viaje", viajeHandler.ListarPorReceptor)
				panelViaje.GET("/telemetria", telemetriaHandler.ListarPorViaje)
				panelViaje.GET("/tareas-viaje-telemetria", handlers.WsHandler(hub))
			}

		}


	}

	
	return r
	

}

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

	// --- RUTAS PÚBLICAS (Login / Registro) ---
	api := r.Group("/api")
	{
		api.POST("/login", authHandler.Login)
		api.POST("/register", authHandler.Registro)
	}

	// --- ZONA PRIVADA (Requiere Sesión Activa) ---
	privadas := r.Group("/api/app")
	privadas.Use(middleware.RequiereAuth()) // 1. Verifica la Cookie/Sesión
	{
		// ZONA ADMIN
		panelAdmin := privadas.Group("/admin")
		panelAdmin.Use(middleware.RequiereRol("admin"))
		{
			panelAdmin.POST("/crear-clinica", clinicaHandler.CrearClinica)

		}
	}

	// ==========================================
	// EL TÚNEL DE TELEMETRÍA (WebSockets con Sesiones)
	// ==========================================

	// ¡Aquí está la magia de las Cookies!
	// Como el navegador envía la Cookie de sesión automáticamente incluso al abrir un WebSocket,
	// podemos proteger esta ruta con los mismos middlewares.
	// wsGroup := r.Group("/api/ws")
	// wsGroup.Use(middleware.RequiereAuth())           // Debe estar logueado
	// wsGroup.Use(middleware.RequiereRol("conductor")) // SOLO para conductores
	// {
	// 	wsGroup.GET("/telemetria", handlers.WsHandler(hub))
	// }

	return r
}

package routes

import (
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/jmoiron/sqlx"

	"backend/internal/repository"
	"backend/internal/service"
	"backend/internal/handlers"
	"backend/internal/server/middleware"
	"backend/internal/websockets"

)

func ConfigurarRutas(db *sqlx.DB, hub *websockets.Hub) *gin.Engine {

	r := gin.Default()
    
    // Configuración CORS estricta requerida para Sesiones/Cookies
	r.Use(cors.New(cors.Config{
		// Si tu frontend está en el puerto 3000, debes ponerlo explícitamente. "*" no funciona con credenciales.
		AllowOrigins:     []string{"http://localhost:3000"}, 
		AllowMethods:     []string{"POST", "GET", "OPTIONS", "PUT", "DELETE"},
		AllowHeaders:     []string{"Origin", "Content-Type"},
		AllowCredentials: true, // ¡CRÍTICO PARA SESIONES!
		MaxAge:           12 * time.Hour,
	}))

	r.Use(middleware.AuditoriaMiddleware())

	// Inyecciones
	usuarioRepo := repository.NewUsuarioRepository(db)
	usuarioService := service.NewUsuarioService(usuarioRepo)
	authHandler := handlers.NewAuthHandler(usuarioService)

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
		// ZONA MAPA (Admins y Pasajeros)
		mapa := privadas.Group("/mapa")
		mapa.Use(middleware.RequiereRol("admin", "pasajero")) 
		{
			mapa.GET("/datos", func(c *gin.Context) { c.JSON(200, gin.H{"msg": "Datos del mapa"}) })
		}

		// ZONA ADMIN (Exclusiva)
		panelAdmin := privadas.Group("/admin")
		panelAdmin.Use(middleware.RequiereRol("admin"))
		{
			panelAdmin.POST("/crear-usuario", func(c *gin.Context) { c.JSON(200, gin.H{"msg": "OK"}) })
		}
	}

	// ==========================================
	// EL TÚNEL DE TELEMETRÍA (WebSockets con Sesiones)
	// ==========================================
	
	// ¡Aquí está la magia de las Cookies!
	// Como el navegador envía la Cookie de sesión automáticamente incluso al abrir un WebSocket,
	// podemos proteger esta ruta con los mismos middlewares.
	wsGroup := r.Group("/api/ws")
	wsGroup.Use(middleware.RequiereAuth())             // Debe estar logueado
	wsGroup.Use(middleware.RequiereRol("conductor"))   // SOLO para conductores
	{
		wsGroup.GET("/telemetria", handlers.WsHandler(hub))
	}

	return r
}
// internal/server/middleware/session_middleware.go
package middleware

import (
	"net/http"
	"github.com/gin-contrib/sessions"
	"github.com/gin-gonic/gin"
)

// RequiereAuth verifica que el usuario haya hecho login
func RequiereAuth() gin.HandlerFunc {
	return func(c *gin.Context) {
		session := sessions.Default(c)
		usuarioID := session.Get("usuario_id")
		
		if usuarioID == nil {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Debes iniciar sesión"})
			return
		}
		c.Next()
	}
}

// RequiereRol verifica que el rol guardado en sesión coincida con los permitidos
func RequiereRol(rolesPermitidos ...string) gin.HandlerFunc {
	return func(c *gin.Context) {
		session := sessions.Default(c)
		rolObj := session.Get("rol")
		
		if rolObj == nil {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Rol no encontrado"})
			return
		}

		rolStr := rolObj.(string)
		permitido := false

		for _, rol := range rolesPermitidos {
			if rolStr == rol {
				permitido = true
				break
			}
		}

		if !permitido {
			c.AbortWithStatusJSON(http.StatusForbidden, gin.H{"error": "No tienes permisos"})
			return
		}

		c.Next()
	}
}
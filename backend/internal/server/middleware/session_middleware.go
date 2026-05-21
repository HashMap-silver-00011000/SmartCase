// internal/server/middleware/session_middleware.go
package middleware

import (
	"net/http"
	"os"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
)

// RequiereAuth verifica que el usuario haya hecho login
func RequiereAuth(rolRequerido string) gin.HandlerFunc {
	return func(c *gin.Context) {
		tokenString, err := c.Cookie("smart_session")
		if err != nil || tokenString == "" {
			auth := c.GetHeader("Authorization")
			if strings.HasPrefix(auth, "Bearer ") {
				tokenString = strings.TrimSpace(strings.TrimPrefix(auth, "Bearer "))
			}
		}
		// WebSocket en móvil/Flutter a veces no envía Cookie; ?token= en la URL.
		if tokenString == "" {
			tokenString = c.Query("token")
		}
		if tokenString == "" {
			c.AbortWithStatus(http.StatusUnauthorized)
			return
		}

		//verificar que el token es valido
		token, err := jwt.Parse(tokenString, func(token *jwt.Token) (any, error) {
			return []byte(os.Getenv("SECRET")), nil
		},jwt.WithValidMethods([]string{jwt.SigningMethodHS256.Alg()}))//aceptar header con algoritmo
		if err != nil {
			c.AbortWithStatus(http.StatusUnauthorized)
			return 
		}

		if claims, ok := token.Claims.(jwt.MapClaims); ok {
			
			rolDelToken, okRol := claims["rol"].(string)
			if !okRol {
				c.AbortWithStatus(http.StatusUnauthorized)
				return
			}

			if rolDelToken != rolRequerido {
				c.AbortWithStatus(http.StatusForbidden)
				return
			}

			idDelUsuario, okId := claims["sub"].(string)
			if !okId {
				c.AbortWithStatus(http.StatusUnauthorized)
				return
			}
			
			c.Set("id_usuario", idDelUsuario)
			c.Set("rol", rolDelToken)
			c.Next()
		}else {
			c.AbortWithStatus(http.StatusUnauthorized)
			return 
		}
	}

}


package main

import (
	"log"

	"github.com/joho/godotenv"
	process "github.com/markmusic27/workspace/utils"
)

func main() {
	// Setup ENV
	err := godotenv.Load()

	if err != nil {
		log.Fatal("Error loading ENV: " + err.Error())
		return
	}

	// Setup API
	// api := gin.Default()

	// const port = "8080"

	// api.GET("/ping", func(c *gin.Context) {
	// 	c.JSON(200, gin.H{
	// 		"message": "pong",
	// 	})
	// })

	// api.POST("/sms", handlers.InboundSMSRequest)
	// api.POST("/api", handlers.InboundHTTPRequest)

	// log.Println("Starting server on port " + port)
	// api.Run(":" + port)

	process.Message("+506 71099519", "Logged ✅")
}

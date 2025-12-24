// Ollama Control Service - OCS
// Repo = github.com/freigthdev/main/ocs
// Path = cmd/main.go

package main

import (
	// stdlib
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"

	// third-party
	"github.com/gorilla/mux"
	"github.com/rs/zerolog"

	// internal
	"ocs/api"
	"ocs/api/handler"
	"ocs/api/routing"
	"ocs/managers"
	"ocs/models"
	"ocs/src/tools"
)

func main() {
	// Initialize logger
	zerolog.TimeFieldFormat = zerolog.TimeFormatRFC3339
	log.Logger = zerolog.New(os.Stdout).With().Timestamp().Logger()

	// Create context with cancellation
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// Initialize managers
	configManager := managers.NewConfigManager()
	modelManager := managers.NewModelManager("http://localhost:11434", configManager)
	memoryManager := managers.NewMemoryManager(configManager)
	sessionManager := managers.NewSessionManager(configManager, nil, memoryManager)
	tokenManager := managers.NewTokenManager(configManager)
	inferenceManager := managers.NewInferenceManager(modelManager, tokenManager, configManager)
	conversationManager := managers.NewConversationManager(configManager, sessionManager, memoryManager, tokenManager, inferenceManager)
	diskManager, err := managers.NewDiskManager(configManager, memoryManager, sessionManager, conversationManager)
	if err != nil {
		log.Fatal().Err(err).Msg("Failed to initialize disk manager")
	}
	wsManager := managers.NewWebSocketManager(configManager, sessionManager, modelManager, tokenManager)

	// Initialize models
	codeModel := models.NewCodeModel("codellama", &managers.ModelConfig{
		Name:           "codellama",
		Specialization: "code",
		Priority:       1,
	}, modelManager, tokenManager, diskManager)
	chatModel := models.NewChatModel("llama3.2", &managers.ModelConfig{
		Name:           "llama3.2",
		Specialization: "chat",
		Priority:       2,
	}, modelManager, tokenManager, diskManager)
	reasoningModel := models.NewReasoningModel("llama3.2", &managers.ModelConfig{
		Name:           "llama3.2",
		Specialization: "reasoning",
		Priority:       3,
	}, modelManager, tokenManager, diskManager)

	// Initialize tools
	codeTool := tools.NewCodeTool(diskManager, sessionManager)
	fileTool := tools.NewFileTool(diskManager)
	searchTool := tools.NewSearchTool(memoryManager, sessionManager)

	// Initialize model router
	modelRouter := routing.NewModelRouter(codeModel, chatModel, reasoningModel, modelManager)

	// Set router in InferenceManager
	inferenceManager.SetModelRouter(modelRouter)

	// Initialize API handlers
	authHandler := handler.NewAuthenticationHandler(configManager, sessionManager, tokenManager)
	wsHandler := handler.NewWebSocketHandler(wsManager, inferenceManager, codeTool, fileTool, searchTool)
	restAPI := api.NewRESTAPI(configManager, modelManager, sessionManager, inferenceManager, tokenManager, diskManager, conversationManager, codeTool, fileTool, searchTool)
	grpcServer := api.NewOCSGrpcServer(configManager, modelManager, sessionManager, inferenceManager, tokenManager, diskManager, conversationManager, codeTool, fileTool, searchTool)

	// Initialize models
	if err := modelManager.Initialize(ctx); err != nil {
		log.Fatal().Err(err).Msg("Failed to initialize model manager")
	}
	if err := codeModel.Initialize(ctx); err != nil {
		log.Fatal().Err(err).Msg("Failed to initialize code model")
	}
	if err := chatModel.Initialize(ctx); err != nil {
		log.Fatal().Err(err).Msg("Failed to initialize chat model")
	}
	if err := reasoningModel.Initialize(ctx); err != nil {
		log.Fatal().Err(err).Msg("Failed to initialize reasoning model")
	}

	// Set up HTTP server with authentication
	router := mux.NewRouter()
	router.HandleFunc("/api/v1/auth", authHandler.Authenticate).Methods("POST")
	protected := router.PathPrefix("/api/v1").Subrouter()
	protected.Use(authHandler.Middleware)
	protected.HandleFunc("/ws", wsHandler.HandleWebSocket).Methods("GET")
	protected.PathPrefix("/").HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		restAPI.handleListModels(w, r)
	})

	// Start servers
	httpServer := &http.Server{
		Addr:    ":8080",
		Handler: router,
	}

	go func() {
		log.Info().Msg("Starting REST server on :8080")
		if err := httpServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatal().Err(err).Msg("REST server failed")
		}
	}()

	go func() {
		log.Info().Msg("Starting gRPC server on :9090")
		if err := grpcServer.Start(ctx, ":9090"); err != nil {
			log.Fatal().Err(err).Msg("gRPC server failed")
		}
	}()

	// Handle graceful shutdown
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)
	<-sigChan

	log.Info().Msg("Shutting down servers")
	cancel()

	if err := httpServer.Shutdown(context.Background()); err != nil {
		log.Error().Err(err).Msg("Failed to shutdown HTTP server")
	}
	if err := diskManager.Shutdown(context.Background()); err != nil {
		log.Error().Err(err).Msg("Failed to shutdown disk manager")
	}
	if err := codeModel.Shutdown(context.Background()); err != nil {
		log.Error().Err(err).Msg("Failed to shutdown code model")
	}
	if err := chatModel.Shutdown(context.Background()); err != nil {
		log.Error().Err(err).Msg("Failed to shutdown chat model")
	}
	if err := reasoningModel.Shutdown(context.Background()); err != nil {
		log.Error().Err(err).Msg("Failed to shutdown reasoning model")
	}

	log.Info().Msg("OCS shutdown complete")
}

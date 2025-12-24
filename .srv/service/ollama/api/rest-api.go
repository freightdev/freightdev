// Ollama Control Service - OCS
// Repo = github.com/freigthdev/main/ocs
// Path = api/rest-api.go

package api

import (
	// stdlib
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"time"

	// thrid-party
	"github.com/gorilla/mux"
	"github.com/rs/zerolog/log"

	// internal
	"ocs/managers"
	"ocs/src/tools"
)

// RESTAPI handles HTTP REST endpoints for OCS
type RESTAPI struct {
	configManager    *managers.ConfigManager
	modelManager     *managers.ModelManager
	sessionManager   *managers.SessionManager
	inferenceManager *managers.InferenceManager
	tokenManager     *managers.TokenManager
	diskManager      *managers.DiskManager
	conversationMgr  *managers.ConversationManager
	codeTool         *tools.CodeTool
	fileTool         *tools.FileTool
	searchTool       *tools.SearchTool
}

// NewRESTAPI creates a new REST API instance
func NewRESTAPI(
	configManager *managers.ConfigManager,
	modelManager *managers.ModelManager,
	sessionManager *managers.SessionManager,
	inferenceManager *managers.InferenceManager,
	tokenManager *managers.TokenManager,
	diskManager *managers.DiskManager,
	conversationMgr *managers.ConversationManager,
	codeTool *tools.CodeTool,
	fileTool *tools.FileTool,
	searchTool *tools.SearchTool,
) *RESTAPI {
	return &RESTAPI{
		configManager:    configManager,
		modelManager:     modelManager,
		sessionManager:   sessionManager,
		inferenceManager: inferenceManager,
		tokenManager:     tokenManager,
		diskManager:      diskManager,
		conversationMgr:  conversationMgr,
		codeTool:         codeTool,
		fileTool:         fileTool,
		searchTool:       searchTool,
	}
}

// Start starts the REST API server
func (api *RESTAPI) Start(ctx context.Context, addr string) error {
	router := mux.NewRouter()
	router.HandleFunc("/api/v1/models", api.handleListModels).Methods("GET")
	router.HandleFunc("/api/v1/sessions", api.handleCreateSession).Methods("POST")
	router.HandleFunc("/api/v1/sessions/{sessionID}", api.handleGetSession).Methods("GET")
	router.HandleFunc("/api/v1/sessions/{sessionID}/messages", api.handleAddMessage).Methods("POST")
	router.HandleFunc("/api/v1/inference", api.handleInference).Methods("POST")
	router.HandleFunc("/api/v1/tools", api.handleToolCall).Methods("POST")

	srv := &http.Server{
		Addr:         addr,
		Handler:      router,
		ReadTimeout:  30 * time.Second,
		WriteTimeout: 30 * time.Second,
	}

	go func() {
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Error().Err(err).Msg("REST API server failed")
		}
	}()

	<-ctx.Done()
	return srv.Shutdown(context.Background())
}

// handleListModels returns available models
func (api *RESTAPI) handleListModels(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	availableModels, err := api.modelManager.listAvailableModels(ctx)
	if err != nil {
		http.Error(w, fmt.Sprintf("failed to list models: %v", err), http.StatusInternalServerError)
		return
	}

	loadedModels := api.modelManager.GetLoadedModels()
	response := map[string]interface{}{
		"available": availableModels.Models,
		"loaded":    loadedModels,
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(response); err != nil {
		log.Error().Err(err).Msg("Failed to encode models response")
	}
}

// handleCreateSession creates a new session
func (api *RESTAPI) handleCreateSession(w http.ResponseWriter, r *http.Request) {
	var req struct {
		UserID    string                    `json:"user_id"`
		ModelName string                    `json:"model_name"`
		Settings  *managers.SessionSettings `json:"settings"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid request body", http.StatusBadRequest)
		return
	}

	session, err := api.sessionManager.CreateSession(r.Context(), req.UserID, req.ModelName, req.Settings)
	if err != nil {
		http.Error(w, fmt.Sprintf("failed to create session: %v", err), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	if err := json.NewEncoder(w).Encode(session); err != nil {
		log.Error().Err(err).Msg("Failed to encode session response")
	}
}

// handleGetSession retrieves a session
func (api *RESTAPI) handleGetSession(w http.ResponseWriter, r *http.Request) {
	sessionID := mux.Vars(r)["sessionID"]
	session, exists := api.sessionManager.GetSession(sessionID)
	if !exists {
		http.Error(w, "session not found", http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(session); err != nil {
		log.Error().Err(err).Msg("Failed to encode session response")
	}
}

// handleAddMessage adds a message to a session
func (api *RESTAPI) handleAddMessage(w http.ResponseWriter, r *http.Request) {
	sessionID := mux.Vars(r)["sessionID"]
	var req struct {
		Role     string                 `json:"role"`
		Content  string                 `json:"content"`
		Metadata map[string]interface{} `json:"metadata"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid request body", http.StatusBadRequest)
		return
	}

	message, err := api.sessionManager.AddMessage(sessionID, req.Role, req.Content, req.Metadata)
	if err != nil {
		http.Error(w, fmt.Sprintf("failed to add message: %v", err), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(message); err != nil {
		log.Error().Err(err).Msg("Failed to encode message response")
	}
}

// handleInference processes an inference request
func (api *RESTAPI) handleInference(w http.ResponseWriter, r *http.Request) {
	var req struct {
		UserID        string                 `json:"user_id"`
		SessionID     string                 `json:"session_id"`
		Prompt        string                 `json:"prompt"`
		ModelName     string                 `json:"model_name"`
		InferenceType string                 `json:"inference_type"`
		Parameters    map[string]interface{} `json:"parameters"`
		Metadata      map[string]interface{} `json:"metadata"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid request body", http.StatusBadRequest)
		return
	}

	var inferenceReq *managers.InferenceRequest
	switch strings.ToLower(req.InferenceType) {
	case "code":
		inferenceReq = &managers.InferenceRequest{
			ID:          fmt.Sprintf("code_%s", req.UserID),
			UserID:      req.UserID,
			SessionID:   req.SessionID,
			ModelName:   req.ModelName,
			RequestType: managers.InferenceTypeCode,
			Messages:    []managers.Message{{Role: "user", Content: req.Prompt}},
			Parameters:  &managers.InferenceParameters{Parameters: req.Parameters},
		}
	case "chat":
		inferenceReq = &managers.InferenceRequest{
			ID:          fmt.Sprintf("chat_%s", req.UserID),
			UserID:      req.UserID,
			SessionID:   req.SessionID,
			ModelName:   req.ModelName,
			RequestType: managers.InferenceTypeChat,
			Messages:    []managers.Message{{Role: "user", Content: req.Prompt}},
			Parameters:  &managers.InferenceParameters{Parameters: req.Parameters},
		}
	case "reasoning":
		inferenceReq = &managers.InferenceRequest{
			ID:          fmt.Sprintf("reasoning_%s", req.UserID),
			UserID:      req.UserID,
			SessionID:   req.SessionID,
			ModelName:   req.ModelName,
			RequestType: managers.InferenceTypeReasoning,
			Messages:    []managers.Message{{Role: "user", Content: req.Prompt}},
			Parameters:  &managers.InferenceParameters{Parameters: req.Parameters},
		}
	default:
		http.Error(w, "invalid inference type", http.StatusBadRequest)
		return
	}

	result, err := api.inferenceManager.ProcessInference(r.Context(), inferenceReq)
	if err != nil {
		http.Error(w, fmt.Sprintf("inference failed: %v", err), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(result); err != nil {
		log.Error().Err(err).Msg("Failed to encode inference response")
	}
}

// handleToolCall processes a tool call
func (api *RESTAPI) handleToolCall(w http.ResponseWriter, r *http.Request) {
	var toolCall managers.ToolCall
	if err := json.NewDecoder(r.Body).Decode(&toolCall); err != nil {
		http.Error(w, "invalid request body", http.StatusBadRequest)
		return
	}

	var result *managers.ToolResult
	var err error
	switch {
	case strings.HasPrefix(toolCall.Name, "execute_code") || strings.HasPrefix(toolCall.Name, "format_code") || strings.HasPrefix(toolCall.Name, "validate_code"):
		result, err = api.codeTool.Execute(r.Context(), &toolCall)
	case strings.HasPrefix(toolCall.Name, "read_file") || strings.HasPrefix(toolCall.Name, "write_file") || strings.HasPrefix(toolCall.Name, "delete_file") || strings.HasPrefix(toolCall.Name, "list_files"):
		result, err = api.fileTool.Execute(r.Context(), &toolCall)
	case strings.HasPrefix(toolCall.Name, "search_memory") || strings.HasPrefix(toolCall.Name, "search_conversation"):
		result, err = api.searchTool.Execute(r.Context(), &toolCall)
	default:
		http.Error(w, fmt.Sprintf("unknown tool: %s", toolCall.Name), http.StatusBadRequest)
		return
	}

	if err != nil {
		http.Error(w, fmt.Sprintf("tool execution failed: %v", err), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(result); err != nil {
		log.Error().Err(err).Msg("Failed to encode tool result")
	}
}

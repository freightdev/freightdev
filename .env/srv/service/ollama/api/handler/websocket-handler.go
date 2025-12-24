// Ollama Control Service - OCS
// Repo = github.com/freigthdev/main/ocs
// Path = api/handler/websocket-handler.go

package handler

import (
	// stdlib
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"

	// third-party
	"github.com/gorilla/websocket"
	"github.com/rs/zerolog/log"

	// internal
	"ocs/managers"
	"ocs/src/tools"
)

// WebSocketHandler handles WebSocket connections
type WebSocketHandler struct {
	wsManager        *managers.WebSocketManager
	inferenceManager *managers.InferenceManager
	codeTool         *tools.CodeTool
	fileTool         *tools.FileTool
	searchTool       *tools.SearchTool
	upgrader         websocket.Upgrader
}

// NewWebSocketHandler creates a new WebSocket handler
func NewWebSocketHandler(
	wsManager *managers.WebSocketManager,
	inferenceManager *managers.InferenceManager,
	codeTool *tools.CodeTool,
	fileTool *tools.FileTool,
	searchTool *tools.SearchTool,
) *WebSocketHandler {
	return &WebSocketHandler{
		wsManager:        wsManager,
		inferenceManager: inferenceManager,
		codeTool:         codeTool,
		fileTool:         fileTool,
		searchTool:       searchTool,
		upgrader: websocket.Upgrader{
			ReadBufferSize:  1024,
			WriteBufferSize: 1024,
			CheckOrigin:     func(r *http.Request) bool { return true }, // TODO: Restrict origins
		},
	}
}

// HandleWebSocket upgrades HTTP to WebSocket and handles messages
func (wh *WebSocketHandler) HandleWebSocket(w http.ResponseWriter, r *http.Request) {
	userID := r.Context().Value("user_id").(string)
	sessionID := r.Context().Value("session_id").(string)

	conn, err := wh.upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Error().Err(err).Msg("Failed to upgrade to WebSocket")
		return
	}
	defer conn.Close()

	client := &managers.ClientConnection{
		UserID:     userID,
		SessionID:  sessionID,
		Connection: conn,
	}
	wh.wsManager.RegisterClient(client)
	defer wh.wsManager.UnregisterClient(client)

	for {
		var msg managers.WebSocketMessage
		if err := conn.ReadJSON(&msg); err != nil {
			log.Error().Err(err).Str("user_id", userID).Msg("Failed to read WebSocket message")
			break
		}

		switch msg.Type {
		case "inference":
			wh.handleInferenceMessage(r.Context(), client, &msg)
		case "tool_call":
			wh.handleToolCallMessage(r.Context(), client, &msg)
		case "file_operation":
			wh.handleFileOperationMessage(r.Context(), client, &msg)
		default:
			wh.sendError(client, fmt.Sprintf("unknown message type: %s", msg.Type))
		}
	}
}

// handleInferenceMessage processes inference requests
func (wh *WebSocketHandler) handleInferenceMessage(ctx context.Context, client *managers.ClientConnection, msg *managers.WebSocketMessage) {
	var req struct {
		Prompt        string                 `json:"prompt"`
		ModelName     string                 `json:"model_name"`
		InferenceType string                 `json:"inference_type"`
		Parameters    map[string]interface{} `json:"parameters"`
	}
	if err := json.Unmarshal(msg.Payload, &req); err != nil {
		wh.sendError(client, "invalid payload")
		return
	}

	inferenceReq := &managers.InferenceRequest{
		ID:         fmt.Sprintf("%s_%s", req.InferenceType, client.UserID),
		UserID:     client.UserID,
		SessionID:  client.SessionID,
		ModelName:  req.ModelName,
		Messages:   []managers.Message{{Role: "user", Content: req.Prompt}},
		Parameters: &managers.InferenceParameters{Parameters: req.Parameters},
	}

	switch req.InferenceType {
	case "code":
		inferenceReq.RequestType = managers.InferenceTypeCode
	case "chat":
		inferenceReq.RequestType = managers.InferenceTypeChat
	case "reasoning":
		inferenceReq.RequestType = managers.InferenceTypeReasoning
	default:
		wh.sendError(client, "invalid inference type")
		return
	}

	result, err := wh.inferenceManager.ProcessInference(ctx, inferenceReq)
	if err != nil {
		wh.sendError(client, fmt.Sprintf("inference failed: %v", err))
		return
	}

	response := managers.WebSocketMessage{
		Type:    "inference_response",
		Payload: mustMarshal(result),
	}
	if err := client.Connection.WriteJSON(response); err != nil {
		log.Error().Err(err).Str("user_id", client.UserID).Msg("Failed to send inference response")
	}
}

// handleToolCallMessage processes tool call requests
func (wh *WebSocketHandler) handleToolCallMessage(ctx context.Context, client *managers.ClientConnection, msg *managers.WebSocketMessage) {
	var toolCall managers.ToolCall
	if err := json.Unmarshal(msg.Payload, &toolCall); err != nil {
		wh.sendError(client, "invalid payload")
		return
	}

	var result *managers.ToolResult
	var err error
	switch {
	case strings.HasPrefix(toolCall.Name, "execute_code") || strings.HasPrefix(toolCall.Name, "format_code") || strings.HasPrefix(toolCall.Name, "validate_code"):
		result, err = wh.codeTool.Execute(ctx, &toolCall)
	case strings.HasPrefix(toolCall.Name, "read_file") || strings.HasPrefix(toolCall.Name, "write_file") || strings.HasPrefix(toolCall.Name, "delete_file") || strings.HasPrefix(toolCall.Name, "list_files"):
		result, err = wh.fileTool.Execute(ctx, &toolCall)
	case strings.HasPrefix(toolCall.Name, "search_memory") || strings.HasPrefix(toolCall.Name, "search_conversation"):
		result, err = wh.searchTool.Execute(ctx, &toolCall)
	default:
		wh.sendError(client, fmt.Sprintf("unknown tool: %s", toolCall.Name))
		return
	}

	if err != nil {
		wh.sendError(client, fmt.Sprintf("tool execution failed: %v", err))
		return
	}

	response := managers.WebSocketMessage{
		Type:    "tool_response",
		Payload: mustMarshal(result),
	}
	if err := client.Connection.WriteJSON(response); err != nil {
		log.Error().Err(err).Str("user_id", client.UserID).Msg("Failed to send tool response")
	}
}

// handleFileOperationMessage processes file operation requests
func (wh *WebSocketHandler) handleFileOperationMessage(ctx context.Context, client *managers.ClientConnection, msg *managers.WebSocketMessage) {
	var fileOp managers.FileOperation
	if err := json.Unmarshal(msg.Payload, &fileOp); err != nil {
		wh.sendError(client, "invalid payload")
		return
	}

	result, err := wh.wsManager.diskManager.HandleFileOperation(ctx, &fileOp)
	if err != nil {
		wh.sendError(client, fmt.Sprintf("file operation failed: %v", err))
		return
	}

	response := managers.WebSocketMessage{
		Type:    "file_operation_response",
		Payload: mustMarshal(result),
	}
	if err := client.Connection.WriteJSON(response); err != nil {
		log.Error().Err(err).Str("user_id", client.UserID).Msg("Failed to send file operation response")
	}
}

// sendError sends an error message to the client
func (wh *WebSocketHandler) sendError(client *managers.ClientConnection, errorMsg string) {
	response := managers.WebSocketMessage{
		Type:    "error",
		Payload: mustMarshal(map[string]string{"error": errorMsg}),
	}
	if err := client.Connection.WriteJSON(response); err != nil {
		log.Error().Err(err).Str("user_id", client.UserID).Msg("Failed to send error message")
	}
}

// mustMarshal marshals data to JSON
func mustMarshal(v interface{}) []byte {
	data, err := json.Marshal(v)
	if err != nil {
		log.Error().Err(err).Msg("Failed to marshal JSON")
		return []byte{}
	}
	return data
}

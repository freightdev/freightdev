// Ollama Control Service - OCS
// Repo = github.com/freigthdev/main/ocs
// Path = managers/websocket-manager.go

package managers

import (
	// stdlib
	"context"
	"net/http"
	"sync"
	"time"

	// third-party
	"github.com/gorilla/websocket"
	"github.com/rs/zerolog/log"

	// internal
    "ocs/src/utils"
)

// WebSocketManager handles all real-time WebSocket connections
type WebSocketManager struct {
	mu                 sync.RWMutex
	connections        map[string]*ClientConnection
	userConnections    map[string][]*ClientConnection
	sessionConnections map[string][]*ClientConnection
	upgrader           websocket.Upgrader
	configManager      *ConfigManager
	sessionManager     *SessionManager
	modelManager       *ModelManager
	tokenManager       *TokenManager
	messageBuffer      chan *WSMessage
	shutdown           chan struct{}
	pingInterval       time.Duration
	pongWait           time.Duration
	writeWait          time.Duration
	maxMessageSize     int64
}

// ClientConnection represents a WebSocket client connection
type ClientConnection struct {
	ID              string                 `json:"id"`
	UserID          string                 `json:"user_id"`
	SessionID       string                 `json:"session_id,omitempty"`
	ConnectedAt     time.Time              `json:"connected_at"`
	LastActivity    time.Time              `json:"last_activity"`
	IsAuthenticated bool                   `json:"is_authenticated"`
	Permissions     []string               `json:"permissions"`
	Metadata        map[string]interface{} `json:"metadata"`
	Connection      *websocket.Conn        `json:"-"`
	SendChan        chan *WSMessage        `json:"-"`
	CloseChan       chan struct{}          `json:"-"`
	mu              sync.Mutex             `json:"-"`
}

// WSMessage represents a WebSocket message
type WSMessage struct {
	ID        string                 `json:"id"`
	Type      string                 `json:"type"`
	UserID    string                 `json:"user_id,omitempty"`
	SessionID string                 `json:"session_id,omitempty"`
	Payload   map[string]interface{} `json:"payload"`
	Timestamp time.Time              `json:"timestamp"`
	RequestID string                 `json:"request_id,omitempty"`
}

// ChatMessage represents a chat message payload
type ChatMessage struct {
	Content     string                 `json:"content"`
	Role        string                 `json:"role"`
	ModelName   string                 `json:"model_name,omitempty"`
	Stream      bool                   `json:"stream"`
	Temperature float64                `json:"temperature,omitempty"`
	MaxTokens   int                    `json:"max_tokens,omitempty"`
	Metadata    map[string]interface{} `json:"metadata,omitempty"`
}

// StreamChunk represents a streaming response chunk
type StreamChunk struct {
	Content    string `json:"content"`
	Done       bool   `json:"done"`
	TokenCount int    `json:"token_count,omitempty"`
	Error      string `json:"error,omitempty"`
}

// SystemEvent represents system events
type SystemEvent struct {
	EventType string                 `json:"event_type"`
	Message   string                 `json:"message"`
	Severity  string                 `json:"severity"`
	Data      map[string]interface{} `json:"data,omitempty"`
	UserID    string                 `json:"user_id,omitempty"`
	SessionID string                 `json:"session_id,omitempty"`
}

// CodeExecution represents code execution request
type CodeExecution struct {
	Language    string                 `json:"language"`
	Code        string                 `json:"code"`
	Environment string                 `json:"environment,omitempty"`
	Timeout     int                    `json:"timeout,omitempty"`
	Args        []string               `json:"args,omitempty"`
	Env         map[string]string      `json:"env,omitempty"`
	Metadata    map[string]interface{} `json:"metadata,omitempty"`
}

// CodeResult represents code execution result
type CodeResult struct {
	Output   string `json:"output"`
	Error    string `json:"error,omitempty"`
	ExitCode int    `json:"exit_code"`
	Duration int64  `json:"duration_ms"`
	Success  bool   `json:"success"`
}

// FileOperation represents file operations
type FileOperation struct {
	Operation string                 `json:"operation"` // read, write, delete, list
	Path      string                 `json:"path"`
	Content   string                 `json:"content,omitempty"`
	Mode      string                 `json:"mode,omitempty"`
	Recursive bool                   `json:"recursive,omitempty"`
	Metadata  map[string]interface{} `json:"metadata,omitempty"`
}

// FileResult represents file operation result
type FileResult struct {
	Success  bool       `json:"success"`
	Content  string     `json:"content,omitempty"`
	Files    []FileInfo `json:"files,omitempty"`
	Error    string     `json:"error,omitempty"`
	Size     int64      `json:"size,omitempty"`
	Modified time.Time  `json:"modified,omitempty"`
}

// FileInfo represents file information
type FileInfo struct {
	Name     string    `json:"name"`
	Path     string    `json:"path"`
	Size     int64     `json:"size"`
	IsDir    bool      `json:"is_dir"`
	Modified time.Time `json:"modified"`
	Mode     string    `json:"mode"`
}

// NewWebSocketManager creates a new WebSocket manager
func NewWebSocketManager(configManager *ConfigManager, sessionManager *SessionManager, modelManager *ModelManager, tokenManager *TokenManager) *WebSocketManager {
	wsm := &WebSocketManager{
		connections:        make(map[string]*ClientConnection),
		userConnections:    make(map[string][]*ClientConnection),
		sessionConnections: make(map[string][]*ClientConnection),
		upgrader: websocket.Upgrader{
			CheckOrigin: func(r *http.Request) bool {
				// TODO: Implement proper origin checking
				return true
			},
			ReadBufferSize:  1024,
			WriteBufferSize: 1024,
		},
		configManager:  configManager,
		sessionManager: sessionManager,
		modelManager:   modelManager,
		tokenManager:   tokenManager,
		messageBuffer:  make(chan *WSMessage, 1000),
		shutdown:       make(chan struct{}),
		pingInterval:   54 * time.Second,
		pongWait:       60 * time.Second,
		writeWait:      10 * time.Second,
		maxMessageSize: 512 * 1024, // 512KB
	}

	// Start message processor
	go wsm.processMessages()

	return wsm
}

// HandleWebSocket upgrades HTTP connection to WebSocket
func (wsm *WebSocketManager) HandleWebSocket(w http.ResponseWriter, r *http.Request, userID string) error {
	conn, err := wsm.upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Error().Err(err).Msg("Failed to upgrade WebSocket connection")
		return err
	}

	client := &ClientConnection{
		ID:              utils.GenerateConnectionID(),
		UserID:          userID,
		ConnectedAt:     time.Now(),
		LastActivity:    time.Now(),
		IsAuthenticated: userID != "",
		Permissions:     []string{"chat", "tools"},
		Metadata:        make(map[string]interface{}),
		Connection:      conn,
		SendChan:        make(chan *WSMessage, 256),
		CloseChan:       make(chan struct{}),
	}

	// Configure connection
	conn.SetReadLimit(wsm.maxMessageSize)
	conn.SetReadDeadline(time.Now().Add(wsm.pongWait))
	conn.SetPongHandler(func(string) error {
		conn.SetReadDeadline(time.Now().Add(wsm.pongWait))
		client.LastActivity = time.Now()
		return nil
	})

	// Register client
	wsm.registerClient(client)

	// Start goroutines
	go wsm.handleClientRead(client)
	go wsm.handleClientWrite(client)
	go wsm.handleClientPing(client)

	log.Info().
		Str("connection_id", client.ID).
		Str("user_id", userID).
		Msg("WebSocket connection established")

	return nil
}

// registerClient registers a new client connection
func (wsm *WebSocketManager) registerClient(client *ClientConnection) {
	wsm.mu.Lock()
	defer wsm.mu.Unlock()

	wsm.connections[client.ID] = client
	wsm.userConnections[client.UserID] = append(wsm.userConnections[client.UserID], client)

	// Send welcome message
	welcome := &WSMessage{
		ID:   utils.GenerateMessageID(),
		Type: "system.welcome",
		Payload: map[string]interface{}{
			"connection_id": client.ID,
			"server_time":   time.Now(),
			"capabilities":  []string{"chat", "streaming", "code_execution", "file_operations"},
		},
		Timestamp: time.Now(),
	}

	select {
	case client.SendChan <- welcome:
	default:
		log.Warn().Str("connection_id", client.ID).Msg("Failed to send welcome message")
	}
}

// unregisterClient removes a client connection
func (wsm *WebSocketManager) unregisterClient(client *ClientConnection) {
	wsm.mu.Lock()
	defer wsm.mu.Unlock()

	delete(wsm.connections, client.ID)

	// Remove from user connections
	userConns := wsm.userConnections[client.UserID]
	for i, conn := range userConns {
		if conn.ID == client.ID {
			wsm.userConnections[client.UserID] = append(userConns[:i], userConns[i+1:]...)
			break
		}
	}

	// Remove from session connections
	if client.SessionID != "" {
		sessionConns := wsm.sessionConnections[client.SessionID]
		for i, conn := range sessionConns {
			if conn.ID == client.ID {
				wsm.sessionConnections[client.SessionID] = append(sessionConns[:i], sessionConns[i+1:]...)
				break
			}
		}
	}

	close(client.SendChan)
	close(client.CloseChan)

	log.Info().
		Str("connection_id", client.ID).
		Str("user_id", client.UserID).
		Msg("WebSocket connection closed")
}

// handleClientRead handles incoming messages from client
func (wsm *WebSocketManager) handleClientRead(client *ClientConnection) {
	defer func() {
		wsm.unregisterClient(client)
		client.Connection.Close()
	}()

	for {
		select {
		case <-client.CloseChan:
			return
		default:
			var msg WSMessage
			err := client.Connection.ReadJSON(&msg)
			if err != nil {
				if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
					log.Error().Err(err).Str("connection_id", client.ID).Msg("WebSocket read error")
				}
				return
			}

			client.LastActivity = time.Now()
			msg.UserID = client.UserID
			msg.Timestamp = time.Now()

			// Add to message buffer for processing
			select {
			case wsm.messageBuffer <- &msg:
			default:
				log.Warn().Str("connection_id", client.ID).Msg("Message buffer full, dropping message")
			}
		}
	}
}

// handleClientWrite handles outgoing messages to client
func (wsm *WebSocketManager) handleClientWrite(client *ClientConnection) {
	ticker := time.NewTicker(wsm.pingInterval)
	defer ticker.Stop()

	for {
		select {
		case message, ok := <-client.SendChan:
			client.Connection.SetWriteDeadline(time.Now().Add(wsm.writeWait))
			if !ok {
				client.Connection.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}

			if err := client.Connection.WriteJSON(message); err != nil {
				log.Error().Err(err).Str("connection_id", client.ID).Msg("WebSocket write error")
				return
			}

		case <-ticker.C:
			client.Connection.SetWriteDeadline(time.Now().Add(wsm.writeWait))
			if err := client.Connection.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}

		case <-client.CloseChan:
			return
		}
	}
}

// handleClientPing sends periodic ping to keep connection alive
func (wsm *WebSocketManager) handleClientPing(client *ClientConnection) {
	ticker := time.NewTicker(wsm.pingInterval)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			client.mu.Lock()
			if time.Since(client.LastActivity) > wsm.pongWait {
				client.mu.Unlock()
				close(client.CloseChan)
				return
			}
			client.mu.Unlock()

		case <-client.CloseChan:
			return
		}
	}
}

// processMessages processes incoming WebSocket messages
func (wsm *WebSocketManager) processMessages() {
	for {
		select {
		case msg := <-wsm.messageBuffer:
			wsm.handleMessage(msg)

		case <-wsm.shutdown:
			return
		}
	}
}

// handleMessage routes and processes a WebSocket message
func (wsm *WebSocketManager) handleMessage(msg *WSMessage) {
	switch msg.Type {
	case "chat.send":
		wsm.handleChatMessage(msg)
	case "session.create":
		wsm.handleSessionCreate(msg)
	case "session.join":
		wsm.handleSessionJoin(msg)
	case "session.leave":
		wsm.handleSessionLeave(msg)
	case "code.execute":
		wsm.handleCodeExecution(msg)
	case "file.operation":
		wsm.handleFileOperation(msg)
	case "system.ping":
		wsm.handlePing(msg)
	default:
		log.Warn().Str("type", msg.Type).Msg("Unknown message type")
		wsm.sendError(msg.UserID, "unknown_message_type", "Unknown message type: "+msg.Type, msg.RequestID)
	}
}

// handleChatMessage processes chat messages
func (wsm *WebSocketManager) handleChatMessage(msg *WSMessage) {
	var chatMsg ChatMessage
	if err := utils.MapToStruct(msg.Payload, &chatMsg); err != nil {
		wsm.sendError(msg.UserID, "invalid_payload", "Invalid chat message payload", msg.RequestID)
		return
	}

	// Check token budget
	estimatedTokens := wsm.tokenManager.EstimateTokens(chatMsg.Content, chatMsg.ModelName)
	tokenReq := &TokenUsageRequest{
		UserID:       msg.UserID,
		SessionID:    msg.SessionID,
		ModelName:    chatMsg.ModelName,
		InputTokens:  int64(estimatedTokens),
		OutputTokens: int64(chatMsg.MaxTokens),
	}

	tokenResp, err := wsm.tokenManager.CheckTokenUsage(tokenReq)
	if err != nil || !tokenResp.Allowed {
		reason := "Token limit exceeded"
		if tokenResp.BlockReason != "" {
			reason = tokenResp.BlockReason
		}
		wsm.sendError(msg.UserID, "token_limit", reason, msg.RequestID)
		return
	}

	// Add message to session
	if msg.SessionID != "" {
		_, err := wsm.sessionManager.AddMessage(msg.SessionID, "user", chatMsg.Content, chatMsg.Metadata)
		if err != nil {
			log.Error().Err(err).Msg("Failed to add message to session")
		}
	}

	// Send chat request to model
	wsm.sendChatToModel(msg, &chatMsg)
}

// sendChatToModel sends chat request to model and streams response
func (wsm *WebSocketManager) sendChatToModel(msg *WSMessage, chatMsg *ChatMessage) {
	// Get session context if available
	var messages []Message
	var err error

	if msg.SessionID != "" {
		messages, err = wsm.sessionManager.GetSessionContext(msg.SessionID, true)
		if err != nil {
			log.Error().Err(err).Msg("Failed to get session context")
		}
	}

	// TODO: Send request to Ollama via model manager
	// This would be integrated with your model manager to actually call Ollama

	// For now, simulate streaming response
	go wsm.simulateStreamingResponse(msg, chatMsg, messages)
}

// simulateStreamingResponse simulates a streaming response (replace with actual Ollama integration)
func (wsm *WebSocketManager) simulateStreamingResponse(msg *WSMessage, chatMsg *ChatMessage, messages []Message) {
	response := "This is a simulated streaming response to: " + chatMsg.Content

	// Send streaming chunks
	words := []string{"This", "is", "a", "simulated", "streaming", "response", "to:", chatMsg.Content}

	for i, word := range words {
		chunk := &StreamChunk{
			Content: word + " ",
			Done:    i == len(words)-1,
		}

		streamMsg := &WSMessage{
			ID:        utils.GenerateMessageID(),
			Type:      "chat.stream",
			UserID:    msg.UserID,
			SessionID: msg.SessionID,
			Payload: map[string]interface{}{
				"chunk":      chunk,
				"request_id": msg.RequestID,
			},
			Timestamp: time.Now(),
		}

		wsm.sendToUser(msg.UserID, streamMsg)
		time.Sleep(100 * time.Millisecond) // Simulate streaming delay
	}

	// Add assistant response to session
	if msg.SessionID != "" {
		wsm.sessionManager.AddMessage(msg.SessionID, "assistant", response, nil)
	}
}

// sendToUser sends a message to all connections for a user
func (wsm *WebSocketManager) sendToUser(userID string, msg *WSMessage) {
	wsm.mu.RLock()
	connections := wsm.userConnections[userID]
	wsm.mu.RUnlock()

	for _, conn := range connections {
		select {
		case conn.SendChan <- msg:
		default:
			log.Warn().Str("connection_id", conn.ID).Msg("Failed to send message to client")
		}
	}
}

// sendToSession sends a message to all connections in a session
func (wsm *WebSocketManager) sendToSession(sessionID string, msg *WSMessage) {
	wsm.mu.RLock()
	connections := wsm.sessionConnections[sessionID]
	wsm.mu.RUnlock()

	for _, conn := range connections {
		select {
		case conn.SendChan <- msg:
		default:
			log.Warn().Str("connection_id", conn.ID).Msg("Failed to send message to client")
		}
	}
}

// sendError sends an error message to a user
func (wsm *WebSocketManager) sendError(userID, errorCode, message, requestID string) {
	errorMsg := &WSMessage{
		ID:     utils.GenerateMessageID(),
		Type:   "error",
		UserID: userID,
		Payload: map[string]interface{}{
			"error_code": errorCode,
			"message":    message,
			"request_id": requestID,
		},
		Timestamp: time.Now(),
	}

	wsm.sendToUser(userID, errorMsg)
}

// handleSessionCreate creates a new session
func (wsm *WebSocketManager) handleSessionCreate(msg *WSMessage) {
	modelName, _ := msg.Payload["model_name"].(string)
	if modelName == "" {
		modelName = "llama3.2" // Default model
	}

	session, err := wsm.sessionManager.CreateSession(context.Background(), msg.UserID, modelName, nil)
	if err != nil {
		wsm.sendError(msg.UserID, "session_create_failed", err.Error(), msg.RequestID)
		return
	}

	responseMsg := &WSMessage{
		ID:     utils.GenerateMessageID(),
		Type:   "session.created",
		UserID: msg.UserID,
		Payload: map[string]interface{}{
			"session_id": session.ID,
			"title":      session.Title,
			"model_name": session.ModelName,
			"created_at": session.CreatedAt,
			"request_id": msg.RequestID,
		},
		Timestamp: time.Now(),
	}

	wsm.sendToUser(msg.UserID, responseMsg)
}

// handleSessionJoin joins a session
func (wsm *WebSocketManager) handleSessionJoin(msg *WSMessage) {
	sessionID, _ := msg.Payload["session_id"].(string)
	if sessionID == "" {
		wsm.sendError(msg.UserID, "missing_session_id", "Session ID is required", msg.RequestID)
		return
	}

	session, exists := wsm.sessionManager.GetSession(sessionID)
	if !exists {
		wsm.sendError(msg.UserID, "session_not_found", "Session not found", msg.RequestID)
		return
	}

	// Update client session
	wsm.mu.Lock()
	for _, conn := range wsm.userConnections[msg.UserID] {
		conn.SessionID = sessionID
		wsm.sessionConnections[sessionID] = append(wsm.sessionConnections[sessionID], conn)
	}
	wsm.mu.Unlock()

	// Send session info
	responseMsg := &WSMessage{
		ID:     utils.GenerateMessageID(),
		Type:   "session.joined",
		UserID: msg.UserID,
		Payload: map[string]interface{}{
			"session_id":    session.ID,
			"title":         session.Title,
			"message_count": session.MessageCount,
			"last_activity": session.LastActivity,
			"request_id":    msg.RequestID,
		},
		Timestamp: time.Now(),
	}

	wsm.sendToUser(msg.UserID, responseMsg)
}

// handlePing responds to ping messages
func (wsm *WebSocketManager) handlePing(msg *WSMessage) {
	pongMsg := &WSMessage{
		ID:     utils.GenerateMessageID(),
		Type:   "system.pong",
		UserID: msg.UserID,
		Payload: map[string]interface{}{
			"timestamp":  time.Now(),
			"request_id": msg.RequestID,
		},
		Timestamp: time.Now(),
	}

	wsm.sendToUser(msg.UserID, pongMsg)
}

// handleCodeExecution processes code execution requests
func (wsm *WebSocketManager) handleCodeExecution(msg *WSMessage) {
	// TODO: Implement code execution
	wsm.sendError(msg.UserID, "not_implemented", "Code execution not yet implemented", msg.RequestID)
}

// handleFileOperation processes file operations
func (wsm *WebSocketManager) handleFileOperation(msg *WSMessage) {
	// TODO: Implement file operations
	wsm.sendError(msg.UserID, "not_implemented", "File operations not yet implemented", msg.RequestID)
}

// handleSessionLeave leaves a session
func (wsm *WebSocketManager) handleSessionLeave(msg *WSMessage) {
	// Remove from session connections
	wsm.mu.Lock()
	for _, conn := range wsm.userConnections[msg.UserID] {
		if conn.SessionID != "" {
			sessionConns := wsm.sessionConnections[conn.SessionID]
			for i, sessionConn := range sessionConns {
				if sessionConn.ID == conn.ID {
					wsm.sessionConnections[conn.SessionID] = append(sessionConns[:i], sessionConns[i+1:]...)
					break
				}
			}
			conn.SessionID = ""
		}
	}
	wsm.mu.Unlock()

	responseMsg := &WSMessage{
		ID:     utils.GenerateMessageID(),
		Type:   "session.left",
		UserID: msg.UserID,
		Payload: map[string]interface{}{
			"request_id": msg.RequestID,
		},
		Timestamp: time.Now(),
	}

	wsm.sendToUser(msg.UserID, responseMsg)
}

// Shutdown gracefully shuts down the WebSocket manager
func (wsm *WebSocketManager) Shutdown(ctx context.Context) error {
	log.Info().Msg("Shutting down WebSocket manager")
	close(wsm.shutdown)

	// Close all connections
	wsm.mu.Lock()
	for _, client := range wsm.connections {
		close(client.CloseChan)
		client.Connection.Close()
	}
	wsm.mu.Unlock()

	log.Info().Msg("WebSocket manager shutdown complete")
	return nil
}

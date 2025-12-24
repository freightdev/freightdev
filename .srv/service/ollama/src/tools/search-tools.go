// Ollama Control Service - OCS
// Repo = github.com/freigthdev/main/ocs
// Path = src/tools/search-tools.go

package tools

import (
	// stdlib
	"context"
	"fmt"
	"strings"
	"time"

	// third-party
	"github.com/rs/zerolog/log"

	// internal
	"ocs/managers"
	"ocs/src/types"
)

// SearchTool handles memory and conversation searches
type SearchTool struct {
	memoryManager  *managers.MemoryManager
	sessionManager *managers.SessionManager
}

// NewSearchTool creates a new search tool
func NewSearchTool(memoryManager *managers.MemoryManager, sessionManager *managers.SessionManager) *SearchTool {
	return &SearchTool{
		memoryManager:  memoryManager,
		sessionManager: sessionManager,
	}
}

// Execute runs a tool call for search operations
func (st *SearchTool) Execute(ctx context.Context, toolCall *types.ToolCall) (*types.ToolResult, error) {
	switch toolCall.Name {
	case "search_memory":
		return st.searchMemory(ctx, toolCall)
	case "search_conversation":
		return st.searchConversation(ctx, toolCall)
	default:
		return &managers.ToolResult{
			Success: false,
			Error:   fmt.Sprintf("unknown tool call: %s", toolCall.Name),
		}, nil
	}
}

// searchMemory searches user memories
func (st *SearchTool) searchMemory(ctx context.Context, toolCall *types.ToolCall) (*types.ToolResult, error) {
	query, ok := toolCall.Arguments["query"].(string)
	if !ok || query == "" {
		return &managers.ToolResult{
			Success: false,
			Error:   "missing or invalid query argument",
		}, nil
	}
	userID, ok := toolCall.Arguments["user_id"].(string)
	if !ok || userID == "" {
		return &managers.ToolResult{
			Success: false,
			Error:   "missing or invalid user_id argument",
		}, nil
	}
	sessionID, _ := toolCall.Arguments["session_id"].(string)

	start := time.Now()
	memories, err := st.memoryManager.SearchMemories(ctx, userID, query)
	if err != nil {
		return &managers.ToolResult{
			Success: false,
			Error:   fmt.Sprintf("memory search failed: %v", err),
		}, nil
	}

	results := make([]string, len(memories))
	for i, memory := range memories {
		results[i] = fmt.Sprintf("Memory ID: %s, Content: %s", memory.ID, memory.Content)
	}
	content := strings.Join(results, "\n")

	log.Info().
		Str("session_id", sessionID).
		Str("user_id", userID).
		Str("query", query).
		Dur("duration", time.Since(start)).
		Msg("Searched memories")

	return &managers.ToolResult{
		Success: true,
		Content: content,
	}, nil
}

// searchConversation searches session conversation logs
func (st *SearchTool) searchConversation(ctx context.Context, toolCall *types.ToolCall) (*types.ToolResult, error) {
	query, ok := toolCall.Arguments["query"].(string)
	if !ok || query == "" {
		return &managers.ToolResult{
			Success: false,
			Error:   "missing or invalid query argument",
		}, nil
	}
	sessionID, ok := toolCall.Arguments["session_id"].(string)
	if !ok || sessionID == "" {
		return &managers.ToolResult{
			Success: false,
			Error:   "missing or invalid session_id argument",
		}, nil
	}

	session, exists := st.sessionManager.GetSession(sessionID)
	if !exists {
		return &managers.ToolResult{
			Success: false,
			Error:   fmt.Sprintf("session not found: %s", sessionID),
		}, nil
	}

	start := time.Now()
	var results []string
	for _, msg := range session.Context.ConversationLog {
		if strings.Contains(strings.ToLower(msg.Content), strings.ToLower(query)) {
			results = append(results, fmt.Sprintf("Message ID: %s, Role: %s, Content: %s", msg.ID, msg.Role, msg.Content))
		}
	}
	content := strings.Join(results, "\n")

	log.Info().
		Str("session_id", sessionID).
		Str("query", query).
		Dur("duration", time.Since(start)).
		Msg("Searched conversation")

	return &managers.ToolResult{
		Success: true,
		Content: content,
	}, nil
}

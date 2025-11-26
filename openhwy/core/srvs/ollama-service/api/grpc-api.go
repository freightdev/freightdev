// Ollama Control Service - OCS
// Repo = github.com/freigthdev/main/ocs
// Path = api/grpc-api.go

package api

import (
	// stdlib
	"context"
	"fmt"
	"net"
	"strings"
	"time"

	// third-party

	"github.com/rs/zerolog/log"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	// internal
	"ocs/managers"
	"ocs/src/tools"
)

// Assuming the following proto definition exists in ocs.proto:
// service OCS {
//   rpc ListModels(ListModelsRequest) returns (ListModelsResponse);
//   rpc CreateSession(CreateSessionRequest) returns (CreateSessionResponse);
//   rpc GetSession(GetSessionRequest) returns (GetSessionResponse);
//   rpc AddMessage(AddMessageRequest) returns (AddMessageResponse);
//   rpc ProcessInference(ProcessInferenceRequest) returns (ProcessInferenceResponse);
//   rpc ExecuteTool(ExecuteToolRequest) returns (ExecuteToolResponse);
// }

// OCSGrpcServer implements the gRPC server for OCS
type OCSGrpcServer struct {
	configManager          *managers.ConfigManager
	modelManager           *managers.ModelManager
	sessionManager         *managers.SessionManager
	inferenceManager       *managers.InferenceManager
	tokenManager           *managers.TokenManager
	diskManager            *managers.DiskManager
	conversationMgr        *managers.ConversationManager
	codeTool               *tools.CodeTool
	fileTool               *tools.FileTool
	searchTool             *tools.SearchTool
	UnimplementedOCSServer // Embed for forward compatibility
}

// NewOCSGrpcServer creates a new gRPC server
func NewOCSGrpcServer(
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
) *OCSGrpcServer {
	return &OCSGrpcServer{
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

// Start starts the gRPC server
func (s *OCSGrpcServer) Start(ctx context.Context, addr string) error {
	grpcServer := grpc.NewServer()
	RegisterOCSServer(grpcServer, s)

	listener, err := net.Listen("tcp", addr)
	if err != nil {
		return fmt.Errorf("failed to listen: %w", err)
	}

	go func() {
		if err := grpcServer.Serve(listener); err != nil {
			log.Error().Err(err).Msg("gRPC server failed")
		}
	}()

	<-ctx.Done()
	grpcServer.GracefulStop()
	return nil
}

// ListModels returns available and loaded models
func (s *OCSGrpcServer) ListModels(ctx context.Context, req *ListModelsRequest) (*ListModelsResponse, error) {
	availableModels, err := s.modelManager.listAvailableModels(ctx)
	if err != nil {
		return nil, status.Error(codes.Internal, fmt.Sprintf("failed to list models: %v", err))
	}

	loadedModels := s.modelManager.GetLoadedModels()
	loaded := make([]*ModelInfo, 0, len(loadedModels))
	for _, model := range loadedModels {
		loaded = append(loaded, &ModelInfo{
			Name:           model.Name,
			Size:           model.Size,
			LoadedAt:       model.LoadedAt.Format(time.RFC3339),
			LastUsed:       model.LastUsed.Format(time.RFC3339),
			Specialization: model.Specialization,
			Priority:       int32(model.Priority),
			Status:         model.Status,
			ErrorMsg:       model.ErrorMsg,
		})
	}

	return &ListModelsResponse{
		Available: availableModels.Models,
		Loaded:    loaded,
	}, nil
}

// CreateSession creates a new session
func (s *OCSGrpcServer) CreateSession(ctx context.Context, req *CreateSessionRequest) (*CreateSessionResponse, error) {
	session, err := s.sessionManager.CreateSession(ctx, req.UserId, req.ModelName, &managers.SessionSettings{
		MaxTokens:         int(req.Settings.MaxTokens),
		Temperature:       req.Settings.Temperature,
		TopP:              req.Settings.TopP,
		RepetitionPenalty: req.Settings.RepetitionPenalty,
		ContextWindow:     int(req.Settings.ContextWindow),
		AutoSave:          req.Settings.AutoSave,
		PersistMemory:     req.Settings.PersistMemory,
		EnableTools:       req.Settings.EnableTools,
		EnableCodeExec:    req.Settings.EnableCodeExec,
	})
	if err != nil {
		return nil, status.Error(codes.Internal, fmt.Sprintf("failed to create session: %v", err))
	}

	return &CreateSessionResponse{
		Session: &Session{
			Id:           session.ID,
			UserId:       session.UserID,
			Title:        session.Title,
			CreatedAt:    session.CreatedAt.Format(time.RFC3339),
			LastActivity: session.LastActivity.Format(time.RFC3339),
			MessageCount: int32(session.MessageCount),
			TokensUsed:   session.TokensUsed,
			ModelName:    session.ModelName,
			IsActive:     session.IsActive,
		},
	}, nil
}

// GetSession retrieves a session
func (s *OCSGrpcServer) GetSession(ctx context.Context, req *GetSessionRequest) (*GetSessionResponse, error) {
	session, exists := s.sessionManager.GetSession(req.SessionId)
	if !exists {
		return nil, status.Error(codes.NotFound, "session not found")
	}

	return &GetSessionResponse{
		Session: &Session{
			Id:           session.ID,
			UserId:       session.UserID,
			Title:        session.Title,
			CreatedAt:    session.CreatedAt.Format(time.RFC3339),
			LastActivity: session.LastActivity.Format(time.RFC3339),
			MessageCount: int32(session.MessageCount),
			TokensUsed:   session.TokensUsed,
			ModelName:    session.ModelName,
			IsActive:     session.IsActive,
		},
	}, nil
}

// AddMessage adds a message to a session
func (s *OCSGrpcServer) AddMessage(ctx context.Context, req *AddMessageRequest) (*AddMessageResponse, error) {
	message, err := s.sessionManager.AddMessage(req.SessionId, req.Role, req.Content, req.Metadata)
	if err != nil {
		return nil, status.Error(codes.Internal, fmt.Sprintf("failed to add message: %v", err))
	}

	return &AddMessageResponse{
		Message: &Message{
			Id:        message.ID,
			Role:      message.Role,
			Content:   message.Content,
			Timestamp: message.Timestamp.Format(time.RFC3339),
			Tokens:    int32(message.Tokens),
			ModelUsed: message.ModelUsed,
		},
	}, nil
}

// ProcessInference processes an inference request
func (s *OCSGrpcServer) ProcessInference(ctx context.Context, req *ProcessInferenceRequest) (*ProcessInferenceResponse, error) {
	inferenceReq := &managers.InferenceRequest{
		ID:         fmt.Sprintf("%s_%s", req.InferenceType, req.UserId),
		UserID:     req.UserId,
		SessionID:  req.SessionId,
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
		return nil, status.Error(codes.InvalidArgument, "invalid inference type")
	}

	result, err := s.inferenceManager.ProcessInference(ctx, inferenceReq)
	if err != nil {
		return nil, status.Error(codes.Internal, fmt.Sprintf("inference failed: %v", err))
	}

	return &ProcessInferenceResponse{
		Content: result.Content,
		Usage: &TokenUsage{
			PromptTokens:     result.Usage.PromptTokens,
			CompletionTokens: result.Usage.CompletionTokens,
			TotalTokens:      result.Usage.TotalTokens,
		},
	}, nil
}

// ExecuteTool processes a tool call
func (s *OCSGrpcServer) ExecuteTool(ctx context.Context, req *ExecuteToolRequest) (*ExecuteToolResponse, error) {
	toolCall := &managers.ToolCall{
		Name:      req.Name,
		Arguments: req.Arguments,
	}

	var result *managers.ToolResult
	var err error
	switch {
	case strings.HasPrefix(req.Name, "execute_code") || strings.HasPrefix(req.Name, "format_code") || strings.HasPrefix(req.Name, "validate_code"):
		result, err = s.codeTool.Execute(ctx, toolCall)
	case strings.HasPrefix(req.Name, "read_file") || strings.HasPrefix(req.Name, "write_file") || strings.HasPrefix(req.Name, "delete_file") || strings.HasPrefix(req.Name, "list_files"):
		result, err = s.fileTool.Execute(ctx, toolCall)
	case strings.HasPrefix(req.Name, "search_memory") || strings.HasPrefix(req.Name, "search_conversation"):
		result, err = s.searchTool.Execute(ctx, toolCall)
	default:
		return nil, status.Error(codes.InvalidArgument, fmt.Sprintf("unknown tool: %s", req.Name))
	}

	if err != nil {
		return nil, status.Error(codes.Internal, fmt.Sprintf("tool execution failed: %v", err))
	}

	return &ExecuteToolResponse{
		Success: result.Success,
		Content: result.Content,
		Error:   result.Error,
	}, nil
}

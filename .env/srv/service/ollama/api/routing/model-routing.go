// Ollama Control Service - OCS
// Repo = github.com/freigthdev/main/ocs
// Path = api/routing/model-routing.go

package routing

import (
	// stdlib
	"context"
	"fmt"

	//third-party

	// internal
	"ocs/managers"
	"ocs/models"
)

// ModelRouter routes inference requests to appropriate model handlers
type ModelRouter struct {
	codeModel      *models.CodeModel
	chatModel      *models.ChatModel
	reasoningModel *models.ReasoningModel
	modelManager   *managers.ModelManager
}

// NewModelRouter creates a new model router
func NewModelRouter(
	codeModel *models.CodeModel,
	chatModel *models.ChatModel,
	reasoningModel *models.ReasoningModel,
	modelManager *managers.ModelManager,
) *ModelRouter {
	return &ModelRouter{
		codeModel:      codeModel,
		chatModel:      chatModel,
		reasoningModel: reasoningModel,
		modelManager:   modelManager,
	}
}

// RouteInference routes inference requests based on type
func (mr *ModelRouter) RouteInference(ctx context.Context, req *managers.InferenceRequest) (*managers.InferenceResult, error) {
	switch req.RequestType {
	case managers.InferenceTypeCode:
		return mr.handleCodeInference(ctx, req)
	case managers.InferenceTypeChat:
		return mr.handleChatInference(ctx, req)
	case managers.InferenceTypeReasoning:
		return mr.handleReasoningInference(ctx, req)
	default:
		return nil, fmt.Errorf("unsupported inference type: %s", req.RequestType)
	}
}

// handleCodeInference processes code inference
func (mr *ModelRouter) handleCodeInference(ctx context.Context, req *managers.InferenceRequest) (*managers.InferenceResult, error) {
	codeReq := &models.CodeInferenceRequest{
		UserID:     req.UserID,
		SessionID:  req.SessionID,
		Prompt:     req.Messages[len(req.Messages)-1].Content,
		Parameters: req.Parameters.Parameters,
		Metadata:   map[string]interface{}{"persist": true},
	}

	// Fetch CodeContext from SessionManager if needed
	session, exists := mr.modelManager.sessionManager.GetSession(req.SessionID)
	if exists && session.Context.CodeContext != nil {
		codeReq.CodeContext = session.Context.CodeContext
	}

	result, err := mr.codeModel.ProcessInference(ctx, codeReq)
	if err != nil {
		return nil, fmt.Errorf("code inference failed: %v", err)
	}

	return &managers.InferenceResult{
		Content: result.Content,
		Usage: &managers.TokenUsage{
			TotalTokens: result.TokensUsed,
		},
		ToolCalls: result.ToolCalls,
	}, nil
}

// handleChatInference processes chat inference
func (mr *ModelRouter) handleChatInference(ctx context.Context, req *managers.InferenceRequest) (*managers.InferenceResult, error) {
	chatReq := &models.ChatInferenceRequest{
		UserID:     req.UserID,
		SessionID:  req.SessionID,
		Prompt:     req.Messages[len(req.Messages)-1].Content,
		Messages:   req.Messages,
		Parameters: req.Parameters.Parameters,
		Metadata:   map[string]interface{}{"persist": true},
	}

	// Fetch UserProfile from SessionManager if needed
	session, exists := mr.modelManager.sessionManager.GetSession(req.SessionID)
	if exists && session.Context.UserProfile != nil {
		chatReq.UserProfile = session.Context.UserProfile
	}

	result, err := mr.chatModel.ProcessInference(ctx, chatReq)
	if err != nil {
		return nil, fmt.Errorf("chat inference failed: %v", err)
	}

	return &managers.InferenceResult{
		Content: result.Content,
		Usage: &managers.TokenUsage{
			TotalTokens: result.TokensUsed,
		},
		ToolCalls: result.ToolCalls,
	}, nil
}

// handleReasoningInference processes reasoning inference
func (mr *ModelRouter) handleReasoningInference(ctx context.Context, req *managers.InferenceRequest) (*managers.InferenceResult, error) {
	reasoningReq := &models.ReasoningInferenceRequest{
		UserID:     req.UserID,
		SessionID:  req.SessionID,
		Prompt:     req.Messages[len(req.Messages)-1].Content,
		Parameters: req.Parameters.Parameters,
		Metadata:   map[string]interface{}{"persist": true},
	}

	// Fetch ConversationContext from ConversationManager if needed
	conversation, exists := mr.modelManager.conversationMgr.GetConversation(req.SessionID)
	if exists {
		reasoningReq.Context = &managers.ConversationContext{
			Topic:     conversation.Topic,
			Intent:    string(conversation.Intent),
			UserGoals: conversation.UserGoals,
		}
	}

	result, err := mr.reasoningModel.ProcessInference(ctx, reasoningReq)
	if err != nil {
		return nil, fmt.Errorf("reasoning inference failed: %v", err)
	}

	return &managers.InferenceResult{
		Content: result.Content,
		Usage: &managers.TokenUsage{
			TotalTokens: result.TokensUsed,
		},
		ToolCalls: result.ToolCalls,
	}, nil
}

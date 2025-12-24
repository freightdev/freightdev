// Ollama Control Service - OCS
// Repo = github.com/freigthdev/main/ocs
// Path = src/tools/file-tools.go

package tools

import (
	// stdlib
	"context"
	"fmt"
	"strings"

	// third-party
	"github.com/rs/zerolog/log"

	// internal
	"ocs/managers"
	"ocs/src/types"
)

// FileTool handles file operations
type FileTool struct {
	diskManager *managers.DiskManager
}

// NewFileTool creates a new file tool
func NewFileTool(diskManager *managers.DiskManager) *FileTool {
	return &FileTool{
		diskManager: diskManager,
	}
}

// Execute runs a tool call for file operations
func (ft *FileTool) Execute(ctx context.Context, toolCall *types.ToolCall) (*types.ToolResult, error) {
	switch toolCall.Name {
	case "read_file":
		return ft.readFile(ctx, toolCall)
	case "write_file":
		return ft.writeFile(ctx, toolCall)
	case "delete_file":
		return ft.deleteFile(ctx, toolCall)
	case "list_files":
		return ft.listFiles(ctx, toolCall)
	default:
		return &managers.ToolResult{
			Success: false,
			Error:   fmt.Sprintf("unknown tool call: %s", toolCall.Name),
		}, nil
	}
}

// readFile reads a file's contents
func (ft *FileTool) readFile(ctx context.Context, toolCall *types.ToolCall) (*types.ToolResult, error) {
	path, ok := toolCall.Arguments["path"].(string)
	if !ok || path == "" {
		return &managers.ToolResult{
			Success: false,
			Error:   "missing or invalid path argument",
		}, nil
	}
	sessionID, _ := toolCall.Arguments["session_id"].(string)

	fileOp := &managers.FileOperation{
		Operation: "read",
		Path:      path,
	}
	result, err := ft.diskManager.HandleFileOperation(ctx, fileOp)
	if err != nil {
		return &managers.ToolResult{
			Success: false,
			Error:   fmt.Sprintf("failed to read file: %v", err),
		}, nil
	}
	if !result.Success {
		return &managers.ToolResult{
			Success: false,
			Error:   result.Error,
		}, nil
	}

	log.Info().
		Str("session_id", sessionID).
		Str("path", path).
		Msg("Read file")

	return &managers.ToolResult{
		Success: true,
		Content: result.Content,
	}, nil
}

// writeFile writes content to a file
func (ft *FileTool) writeFile(ctx context.Context, toolCall *types.ToolCall) (*types.ToolResult, error) {
	path, ok := toolCall.Arguments["path"].(string)
	if !ok || path == "" {
		return &managers.ToolResult{
			Success: false,
			Error:   "missing or invalid path argument",
		}, nil
	}
	content, ok := toolCall.Arguments["content"].(string)
	if !ok {
		return &managers.ToolResult{
			Success: false,
			Error:   "missing or invalid content argument",
		}, nil
	}
	sessionID, _ := toolCall.Arguments["session_id"].(string)

	fileOp := &managers.FileOperation{
		Operation: "write",
		Path:      path,
		Content:   content,
	}
	result, err := ft.diskManager.HandleFileOperation(ctx, fileOp)
	if err != nil {
		return &managers.ToolResult{
			Success: false,
			Error:   fmt.Sprintf("failed to write file: %v", err),
		}, nil
	}
	if !result.Success {
		return &managers.ToolResult{
			Success: false,
			Error:   result.Error,
		}, nil
	}

	log.Info().
		Str("session_id", sessionID).
		Str("path", path).
		Msg("Wrote file")

	return &managers.ToolResult{
		Success: true,
		Content: "File written successfully",
	}, nil
}

// deleteFile deletes a file
func (ft *FileTool) deleteFile(ctx context.Context, toolCall *types.ToolCall) (*types.ToolResult, error) {
	path, ok := toolCall.Arguments["path"].(string)
	if !ok || path == "" {
		return &managers.ToolResult{
			Success: false,
			Error:   "missing or invalid path argument",
		}, nil
	}
	sessionID, _ := toolCall.Arguments["session_id"].(string)

	fileOp := &managers.FileOperation{
		Operation: "delete",
		Path:      path,
	}
	result, err := ft.diskManager.HandleFileOperation(ctx, fileOp)
	if err != nil {
		return &managers.ToolResult{
			Success: false,
			Error:   fmt.Sprintf("failed to delete file: %v", err),
		}, nil
	}
	if !result.Success {
		return &managers.ToolResult{
			Success: false,
			Error:   result.Error,
		}, nil
	}

	log.Info().
		Str("session_id", sessionID).
		Str("path", path).
		Msg("Deleted file")

	return &managers.ToolResult{
		Success: true,
		Content: "File deleted successfully",
	}, nil
}

// listFiles lists files in a directory
func (ft *FileTool) listFiles(ctx context.Context, toolCall *types.ToolCall) (*types.ToolResult, error) {
	path, ok := toolCall.Arguments["path"].(string)
	if !ok || path == "" {
		return &managers.ToolResult{
			Success: false,
			Error:   "missing or invalid path argument",
		}, nil
	}
	recursive, _ := toolCall.Arguments["recursive"].(bool)
	sessionID, _ := toolCall.Arguments["session_id"].(string)

	fileOp := &managers.FileOperation{
		Operation: "list",
		Path:      path,
		Recursive: recursive,
	}
	result, err := ft.diskManager.HandleFileOperation(ctx, fileOp)
	if err != nil {
		return &managers.ToolResult{
			Success: false,
			Error:   fmt.Sprintf("failed to list files: %v", err),
		}, nil
	}
	if !result.Success {
		return &managers.ToolResult{
			Success: false,
			Error:   result.Error,
		}, nil
	}

	paths := make([]string, len(result.Files))
	for i, file := range result.Files {
		paths[i] = file.Path
	}
	content := strings.Join(paths, "\n")

	log.Info().
		Str("session_id", sessionID).
		Str("path", path).
		Msg("Listed files")

	return &managers.ToolResult{
		Success: true,
		Content: content,
	}, nil
}

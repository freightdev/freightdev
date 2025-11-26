// Ollama Control Service - OCS
// Repo = github.com/freigthdev/main/ocs
// Path = src/tools/code-tools.go

package tools

import (
	// stdlib
	"bytes"
	"context"
	"fmt"
	"os"
	"os/exec"
	"strings"
	"time"

	// third-party
	"github.com/rs/zerolog/log"

	// internal
	"ocs/managers"
	"ocs/src/types"
)

// CodeTool handles code execution, formatting, and validation
type CodeTool struct {
	diskManager    *managers.DiskManager
	sessionManager *managers.SessionManager
}

// NewCodeTool creates a new code tool
func NewCodeTool(diskManager *managers.DiskManager, sessionManager *managers.SessionManager) *CodeTool {
	return &CodeTool{
		diskManager:    diskManager,
		sessionManager: sessionManager,
	}
}

// Execute runs a tool call for code operations
func (ct *CodeTool) Execute(ctx context.Context, toolCall *types.ToolCall) (*types.ToolResult, error) {
	switch toolCall.Name {
	case "execute_code":
		return ct.executeCode(ctx, toolCall)
	case "format_code":
		return ct.formatCode(ctx, toolCall)
	case "validate_code":
		return ct.validateCode(ctx, toolCall)
	default:
		return &types.ToolResult{
			Success: false,
			Error:   fmt.Sprintf("unknown tool call: %s", toolCall.Name),
		}, nil
	}
}

// executeCode runs code in the specified language
func (ct *CodeTool) executeCode(ctx context.Context, toolCall *types.ToolCall) (*types.ToolResult, error) {
	code, ok := toolCall.Arguments["code"].(string)
	if !ok || code == "" {
		return &types.ToolResult{
			Success: false,
			Error:   "missing or invalid code argument",
		}, nil
	}
	language, ok := toolCall.Arguments["language"].(string)
	if !ok || language == "" {
		return &types.ToolResult{
			Success: false,
			Error:   "missing or invalid language argument",
		}, nil
	}
	sessionID, _ := toolCall.Arguments["session_id"].(string)

	// Save code to temporary file
	filePath := ct.diskManager.getSessionFilePath(sessionID) + "_code_tmp"
	if err := ct.diskManager.WriteFile(ctx, filePath, code); err != nil {
		return &types.ToolResult{
			Success: false,
			Error:   fmt.Sprintf("failed to save code: %v", err),
		}, nil
	}
	defer os.Remove(filePath)

	var cmd *exec.Cmd
	switch strings.ToLower(language) {
	case "python":
		cmd = exec.CommandContext(ctx, "python", filePath)
	case "javascript", "js":
		cmd = exec.CommandContext(ctx, "node", filePath)
	case "go":
		cmd = exec.CommandContext(ctx, "go", "run", filePath)
	default:
		return &types.ToolResult{
			Success: false,
			Error:   fmt.Sprintf("unsupported language: %s", language),
		}, nil
	}

	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr
	start := time.Now()

	err := cmd.Run()
	output := stdout.String()
	if err != nil {
		output += stderr.String()
	}

	log.Info().
		Str("session_id", sessionID).
		Str("language", language).
		Dur("duration", time.Since(start)).
		Msg("Executed code")

	return &types.ToolResult{
		Success: err == nil,
		Content: output,
		Error:   err.Error(),
	}, nil
}

// formatCode formats code using language-specific tools
func (ct *CodeTool) formatCode(ctx context.Context, toolCall *types.ToolCall) (*types.ToolResult, error) {
	code, ok := toolCall.Arguments["code"].(string)
	if !ok || code == "" {
		return &types.ToolResult{
			Success: false,
			Error:   "missing or invalid code argument",
		}, nil
	}
	language, ok := toolCall.Arguments["language"].(string)
	if !ok || language == "" {
		return &types.ToolResult{
			Success: false,
			Error:   "missing or invalid language argument",
		}, nil
	}
	sessionID, _ := toolCall.Arguments["session_id"].(string)

	var cmd *exec.Cmd
	var formatted string
	switch strings.ToLower(language) {
	case "python":
		var buf bytes.Buffer
		buf.WriteString(code)
		cmd = exec.CommandContext(ctx, "black", "-")
		cmd.Stdin = &buf
	case "javascript", "js":
		var buf bytes.Buffer
		buf.WriteString(code)
		cmd = exec.CommandContext(ctx, "prettier", "--parser", "babel")
		cmd.Stdin = &buf
	case "go":
		var buf bytes.Buffer
		buf.WriteString(code)
		cmd = exec.CommandContext(ctx, "gofmt")
		cmd.Stdin = &buf
	default:
		return &types.ToolResult{
			Success: false,
			Error:   fmt.Sprintf("unsupported language for formatting: %s", language),
		}, nil
	}

	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr
	err := cmd.Run()
	formatted = stdout.String()
	if err != nil {
		return &types.ToolResult{
			Success: false,
			Error:   fmt.Sprintf("formatting failed: %v, %s", err, stderr.String()),
		}, nil
	}

	// Save formatted code
	filePath := ct.diskManager.getSessionFilePath(sessionID) + "_formatted.txt"
	if err := ct.diskManager.WriteFile(ctx, filePath, formatted); err != nil {
		log.Warn().Err(err).Str("session_id", sessionID).Msg("Failed to save formatted code")
	}

	log.Info().
		Str("session_id", sessionID).
		Str("language", language).
		Msg("Formatted code")

	return &types.ToolResult{
		Success: true,
		Content: formatted,
	}, nil
}

// validateCode checks code for syntax errors
func (ct *CodeTool) validateCode(ctx context.Context, toolCall *types.ToolCall) (*types.ToolResult, error) {
	code, ok := toolCall.Arguments["code"].(string)
	if !ok || code == "" {
		return &types.ToolResult{
			Success: false,
			Error:   "missing or invalid code argument",
		}, nil
	}
	language, ok := toolCall.Arguments["language"].(string)
	if !ok || language == "" {
		return &types.ToolResult{
			Success: false,
			Error:   "missing or invalid language argument",
		}, nil
	}
	sessionID, _ := toolCall.Arguments["session_id"].(string)

	var cmd *exec.Cmd
	switch strings.ToLower(language) {
	case "python":
		cmd = exec.CommandContext(ctx, "python", "-m", "py_compile")
	case "javascript", "js":
		cmd = exec.CommandContext(ctx, "node", "--check")
	case "go":
		cmd = exec.CommandContext(ctx, "go", "vet")
	default:
		return &types.ToolResult{
			Success: false,
			Error:   fmt.Sprintf("unsupported language for validation: %s", language),
		}, nil
	}

	// Save code to temporary file
	filePath := ct.diskManager.getSessionFilePath(sessionID) + "_validate_tmp"
	if err := ct.diskManager.WriteFile(ctx, filePath, code); err != nil {
		return &types.ToolResult{
			Success: false,
			Error:   fmt.Sprintf("failed to save code: %v", err),
		}, nil
	}
	defer os.Remove(filePath)

	cmd.Args = append(cmd.Args, filePath)
	var stderr bytes.Buffer
	cmd.Stderr = &stderr
	err := cmd.Run()

	log.Info().
		Str("session_id", sessionID).
		Str("language", language).
		Msg("Validated code")

	if err != nil {
		return &managers.ToolResult{
			Success: false,
			Error:   fmt.Sprintf("validation failed: %v, %s", err, stderr.String()),
		}, nil
	}

	return &managers.ToolResult{
		Success: true,
		Content: "Code is syntactically valid",
	}, nil
}

// Ollama Control Service - OCS
// Repo = github.com/freigthdev/main/ocs
// Path = src/types/tool-types.go

package types

type ToolCall struct {
	Name string
	Args map[string]interface{}
}

type ToolResult struct {
	Success bool
	Error   string
	Output  string
}
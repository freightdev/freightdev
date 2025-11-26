// Ollama Control Service - OCS
// Repo = github.com/freigthdev/main/ocs
// Path = src/utils/generate.go

package utils

import (
	"fmt"
	"time"
)

func GenerateConnectionID() string {
	return fmt.Sprintf("conn_%d", time.Now().UnixNano())
}

func GenerateMessageID() string {
	return fmt.Sprintf("msg_%d", time.Now().UnixNano())
}

// Ollama Control Service - OCS
// Repo = github.com/freigthdev/main/ocs
// Path = src/utils/mapping.go

package utils

import (
	"encoding/json"
)

func MapToStruct(m map[string]interface{}, v interface{}) error {
	data, err := json.Marshal(m)
	if err != nil {
		return err
	}
	return json.Unmarshal(data, v)
}

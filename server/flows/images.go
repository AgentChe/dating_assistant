package flows

import (
	"encoding/base64"
	"net/http"
	"strings"

	"github.com/firebase/genkit/go/ai"

	"github.com/AgentChe/dating_assistant/server/model"
)

// imagePart — картинка из запроса для модели. Тип берётся из самих байтов: приложение шлёт JPEG,
// но PNG, WebP и HEIC модель тоже читает.
func imagePart(field, encoded string) (*ai.Part, error) {
	encoded = strings.TrimSpace(encoded)
	data, err := base64.StdEncoding.DecodeString(encoded)
	if err != nil || len(data) == 0 {
		return nil, &model.InputError{Message: "The " + field + " is not a base64 image"}
	}
	mimeType := imageType(data)
	if mimeType == "" {
		return nil, &model.InputError{Message: "The " + field + " must be a JPEG, PNG, WebP or HEIC image"}
	}
	return ai.NewMediaPart(mimeType, "data:"+mimeType+";base64,"+encoded), nil
}

func imageType(data []byte) string {
	switch mimeType := http.DetectContentType(data); mimeType {
	case "image/jpeg", "image/png", "image/webp":
		return mimeType
	}
	// HEIC — контейнер ISO BMFF: «ftyp» и бренд на байтах 4–12.
	if len(data) >= 12 && string(data[4:8]) == "ftyp" {
		switch string(data[8:12]) {
		case "heic", "heix", "hevc", "heim", "heis", "mif1", "msf1":
			return "image/heic"
		}
	}
	return ""
}

package api

import (
	"context"
	"errors"
	"log"
	"net/http"

	"github.com/firebase/genkit/go/ai"
	"github.com/firebase/genkit/go/core/status"
	"github.com/gin-gonic/gin"

	"github.com/AgentChe/dating_assistant/server/model"
)

// writeError — ошибка в формате, который разбирает RestApiTransport: {"error": {"message": "..."}}.
func writeError(c *gin.Context, code int, message string) {
	c.AbortWithStatusJSON(code, gin.H{"error": gin.H{"message": message}})
}

// writeGenerationError — ошибка генерации в код ответа. Экраны приложения показывают свои тексты,
// а эти — для логов и отладки.
func writeGenerationError(c *gin.Context, err error) {
	var input *model.InputError
	switch {
	case errors.As(err, &input):
		writeError(c, http.StatusBadRequest, input.Message)
	case errors.Is(err, status.ErrInvalidInput):
		// Genkit сверил запрос со схемой из пакета model, и он не подошёл.
		writeError(c, http.StatusBadRequest, "The request doesn’t match the API")
	case errors.Is(err, model.ErrNotAChat):
		writeError(c, http.StatusUnprocessableEntity, "This doesn’t look like a chat screenshot")
	case errors.Is(err, ai.ErrGenerationBlocked):
		logFailure("blocked by safety filters", err)
		writeError(c, http.StatusUnprocessableEntity, "The AI can’t help with this one")
	case errors.Is(err, context.DeadlineExceeded), errors.Is(err, status.ErrDeadlineExceeded):
		logFailure("timed out", err)
		writeError(c, http.StatusGatewayTimeout, "The AI took too long to answer")
	case errors.Is(err, status.ErrResourceExhausted), errors.Is(err, status.ErrUnavailable):
		logFailure("Gemini is busy or out of quota", err)
		writeError(c, http.StatusServiceUnavailable, "The AI is busy, try again in a moment")
	case errors.Is(err, status.ErrPermissionDenied), errors.Is(err, status.ErrUnauthenticated):
		logFailure("Gemini rejected the key: check GEMINI_API_KEY", err)
		writeError(c, http.StatusBadGateway, "The AI couldn’t answer")
	default:
		logFailure("failed", err)
		writeError(c, http.StatusBadGateway, "The AI couldn’t answer")
	}
}

// logFailure пишет причину коротко: в тексте ошибки может оказаться ответ модели с цитатами из переписки.
func logFailure(what string, err error) {
	text := err.Error()
	if len(text) > 300 {
		text = text[:300] + "…"
	}
	log.Printf("generation %s: %s", what, text)
}

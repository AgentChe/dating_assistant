package api

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"errors"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"

	"github.com/AgentChe/dating_assistant/server/model"
)

type handlers struct {
	service Service
	timeout time.Duration
}

// Ответы — то, что вернула модель, плюс id: по нему приложение хранит запись в истории.

type analysisResponse struct {
	ID string `json:"id"`
	*model.ChatBreakdown
}

type openingLineResponse struct {
	ID string `json:"id"`
	*model.OpeningLine
}

type coachResponse struct {
	ID string `json:"id"`
	*model.CoachReply
}

// analyze — POST /api/v1/analyses: разбор переписки по скриншоту.
func (h *handlers) analyze(c *gin.Context) {
	var req model.AnalysisRequest
	if !readJSON(c, &req) {
		return
	}
	if strings.TrimSpace(req.Screenshot) == "" {
		writeError(c, http.StatusBadRequest, "The screenshot is empty")
		return
	}

	ctx, cancel := context.WithTimeout(c.Request.Context(), h.timeout)
	defer cancel()
	breakdown, err := h.service.Analyze(ctx, req)
	if err != nil {
		writeGenerationError(c, err)
		return
	}
	c.JSON(http.StatusOK, analysisResponse{ID: newID("analysis"), ChatBreakdown: breakdown})
}

// openingLine — POST /api/v1/opening-lines: первая фраза для мэтча.
func (h *handlers) openingLine(c *gin.Context) {
	var req model.OpeningLineRequest
	if !readJSON(c, &req) {
		return
	}

	ctx, cancel := context.WithTimeout(c.Request.Context(), h.timeout)
	defer cancel()
	line, err := h.service.OpeningLine(ctx, req)
	if err != nil {
		writeGenerationError(c, err)
		return
	}
	c.JSON(http.StatusOK, openingLineResponse{ID: newID("line"), OpeningLine: line})
}

// coach — POST /api/v1/coach/messages: ответ коуча.
func (h *handlers) coach(c *gin.Context) {
	var req model.CoachRequest
	if !readJSON(c, &req) {
		return
	}

	ctx, cancel := context.WithTimeout(c.Request.Context(), h.timeout)
	defer cancel()
	reply, err := h.service.Coach(ctx, req)
	if err != nil {
		writeGenerationError(c, err)
		return
	}
	c.JSON(http.StatusOK, coachResponse{ID: newID("coach"), CoachReply: reply})
}

// readJSON читает тело запроса; не JSON — 400, больше предела — 413.
func readJSON(c *gin.Context, target any) bool {
	err := json.NewDecoder(c.Request.Body).Decode(target)
	if err == nil {
		return true
	}
	var tooLarge *http.MaxBytesError
	if errors.As(err, &tooLarge) {
		writeError(c, http.StatusRequestEntityTooLarge, "The request is too large")
	} else {
		writeError(c, http.StatusBadRequest, "The request is not valid JSON")
	}
	return false
}

// newID — «analysis-3f9c…»: приложение хранит по нему запись в истории, поэтому id случайный.
func newID(prefix string) string {
	var bytes [8]byte
	_, _ = rand.Read(bytes[:])
	return prefix + "-" + hex.EncodeToString(bytes[:])
}

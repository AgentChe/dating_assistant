// Package api — HTTP-слой сервера на Gin: маршруты, проверка запросов, таймауты и ошибки в формате,
// которого ждёт RestApiTransport в приложении: {"error": {"message": "..."}}.
package api

import (
	"context"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"

	"github.com/AgentChe/dating_assistant/server/model"
)

// Service — то, что умеет ИИ. На сервере это flows.Service, в тестах — фейк.
type Service interface {
	Analyze(ctx context.Context, req model.AnalysisRequest) (*model.ChatBreakdown, error)
	OpeningLine(ctx context.Context, req model.OpeningLineRequest) (*model.OpeningLine, error)
	Coach(ctx context.Context, req model.CoachRequest) (*model.CoachReply, error)
}

// Options — пределы запросов; нулевое значение — по умолчанию.
type Options struct {
	// Сколько ждать модель (по умолчанию 45 с). Приложение ждёт ответа 60 секунд,
	// поэтому сервер сдаётся раньше и успевает ответить понятной ошибкой.
	GenerationTimeout time.Duration
	// Предел тела запроса (по умолчанию 15 МБ): скриншот в base64 весит мегабайты.
	MaxBodyBytes int64
}

// NewRouter — маршруты API.
func NewRouter(service Service, options Options) *gin.Engine {
	if options.GenerationTimeout <= 0 {
		options.GenerationTimeout = 45 * time.Second
	}
	if options.MaxBodyBytes <= 0 {
		options.MaxBodyBytes = 15 << 20
	}
	h := &handlers{service: service, timeout: options.GenerationTimeout}

	router := gin.New()
	// В лог идут метод, путь, код и время ответа. Тела запросов со скриншотами и переписками туда не попадают.
	router.Use(gin.Logger(), gin.Recovery())
	router.GET("/healthz", func(c *gin.Context) { c.String(http.StatusOK, "ok") })

	v1 := router.Group("/api/v1", limitBody(options.MaxBodyBytes))
	v1.POST("/analyses", h.analyze)
	v1.POST("/opening-lines", h.openingLine)
	v1.POST("/coach/messages", h.coach)

	router.NoRoute(func(c *gin.Context) { writeError(c, http.StatusNotFound, "Not found") })
	return router
}

// limitBody обрывает чтение тела после n байт: такой запрос получит 413.
func limitBody(n int64) gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Request.Body = http.MaxBytesReader(c.Writer, c.Request.Body, n)
		c.Next()
	}
}

// Сервер Cue — прокси к Gemini для трёх функций приложения: разбора переписки, первой фразы и коуча.
// Ничего не хранит: всё нужное приходит в запросе, ответ модели уходит обратно в приложение.
//
// Запуск на Mac: положите ключ в server/.env (см. .env.example) и выполните `go run .` в папке server.
package main

import (
	"context"
	"errors"
	"log"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"github.com/firebase/genkit/go/genkit"
	"github.com/firebase/genkit/go/plugins/googlegenai"
	"github.com/gin-gonic/gin"

	"github.com/AgentChe/dating_assistant/server/api"
	"github.com/AgentChe/dating_assistant/server/flows"
)

func main() {
	loadEnvFile(".env")
	if os.Getenv("GEMINI_API_KEY") == "" && os.Getenv("GOOGLE_API_KEY") == "" {
		log.Fatal("GEMINI_API_KEY is not set: put it into server/.env (see .env.example) or into the environment")
	}
	if os.Getenv(gin.EnvGinMode) == "" {
		gin.SetMode(gin.ReleaseMode)
	}

	// Плагин сам берёт ключ из GEMINI_API_KEY.
	g := genkit.Init(context.Background(), genkit.WithPlugins(&googlegenai.GoogleAI{}))
	modelName := envOr("GEMINI_MODEL", flows.DefaultModel)
	service := flows.New(g, flows.GeminiModels(modelName))

	server := &http.Server{
		// HOST=127.0.0.1 — только для nginx на той же машине: снаружи сервер доступен лишь через HTTPS.
		Addr:              strings.TrimSpace(os.Getenv("HOST")) + ":" + envOr("PORT", "8080"),
		Handler:           api.NewRouter(service, api.Options{}),
		ReadHeaderTimeout: 10 * time.Second,
		ReadTimeout:       60 * time.Second,
		WriteTimeout:      90 * time.Second,
		IdleTimeout:       120 * time.Second,
	}
	go func() {
		log.Printf("Cue server is listening on %s, model %s", server.Addr, modelName)
		if err := server.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			log.Fatal(err)
		}
	}()

	// Хостинг останавливает сервер сигналом: даём начатым генерациям договорить.
	stop := make(chan os.Signal, 1)
	signal.Notify(stop, syscall.SIGINT, syscall.SIGTERM)
	<-stop
	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()
	if err := server.Shutdown(ctx); err != nil {
		log.Printf("shutdown: %v", err)
	}
}

func envOr(key, fallback string) string {
	if value := strings.TrimSpace(os.Getenv(key)); value != "" {
		return value
	}
	return fallback
}

// loadEnvFile читает строки KEY=VALUE — так ключ живёт в server/.env на Mac.
// Переменные, заданные в окружении (на хостинге), важнее файла.
func loadEnvFile(path string) {
	data, err := os.ReadFile(path)
	if err != nil {
		return
	}
	for _, line := range strings.Split(string(data), "\n") {
		line = strings.TrimSpace(line)
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		key, value, ok := strings.Cut(line, "=")
		if !ok {
			continue
		}
		key, value = strings.TrimSpace(key), strings.Trim(strings.TrimSpace(value), `"'`)
		if _, exists := os.LookupEnv(key); !exists && value != "" {
			_ = os.Setenv(key, value)
		}
	}
}

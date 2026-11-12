// Package flows — три флоу Genkit, по одному на функцию приложения: разбор переписки, первая фраза и ответ коуча.
// Флоу собирает промпт из запроса, просит у модели JSON по схеме из пакета model и приводит ответ в порядок.
package flows

import (
	"context"
	"embed"
	"errors"
	"strings"

	"github.com/firebase/genkit/go/ai"
	"github.com/firebase/genkit/go/core"
	"github.com/firebase/genkit/go/genkit"
	"github.com/firebase/genkit/go/plugins/googlegenai"
	"google.golang.org/genai"

	"github.com/AgentChe/dating_assistant/server/model"
)

// DefaultModel — модель Gemini, если не задана переменная окружения GEMINI_MODEL. Версия зафиксирована,
// а не «latest»: промпты проверены на ней. На тех же запросах 3.5 Flash отвечала так же быстро,
// но хуже держала инструкции — повторяла слова из примера, придумывала факты, называла мэтча «she».
const DefaultModel = "googleai/gemini-3.8-flash"

// Models — какой моделью пишется каждый ответ. На сервере — Gemini (GeminiModels), в тестах — фейковая модель.
type Models struct {
	Analysis    ai.ModelArg
	OpeningLine ai.ModelArg
	Coach       ai.ModelArg
}

// GeminiModels — модель Gemini с настройками для всех трёх задач.
func GeminiModels(name string) Models {
	ref := googlegenai.ModelRef(name, &genai.GenerateContentConfig{ThinkingConfig: thinking(name)})
	return Models{Analysis: ref, OpeningLine: ref, Coach: ref}
}

// thinking — короткие размышления: задачи небольшие, а ответ пользователь ждёт на экране.
// Gemini 2.x задаёт их бюджетом токенов, Gemini 3 и новее — уровнем.
func thinking(model string) *genai.ThinkingConfig {
	if strings.Contains(model, "gemini-2") {
		return &genai.ThinkingConfig{ThinkingBudget: genai.Ptr[int32](1024)}
	}
	return &genai.ThinkingConfig{ThinkingLevel: genai.ThinkingLevelLow}
}

// Service — три флоу. Каждый виден в Genkit Dev UI вместе с трассировкой вызова модели.
type Service struct {
	analyze     *core.Flow[model.AnalysisRequest, *model.ChatBreakdown, struct{}]
	openingLine *core.Flow[model.OpeningLineRequest, *model.OpeningLine, struct{}]
	coach       *core.Flow[model.CoachRequest, *model.CoachReply, struct{}]
}

// New регистрирует флоу в Genkit.
func New(g *genkit.Genkit, models Models) *Service {
	return &Service{
		analyze: genkit.DefineFlow(g, "analyzeChat",
			func(ctx context.Context, req model.AnalysisRequest) (*model.ChatBreakdown, error) {
				return analyzeChat(ctx, g, models.Analysis, req)
			}),
		openingLine: genkit.DefineFlow(g, "writeOpeningLine",
			func(ctx context.Context, req model.OpeningLineRequest) (*model.OpeningLine, error) {
				return writeOpeningLine(ctx, g, models.OpeningLine, req)
			}),
		coach: genkit.DefineFlow(g, "replyAsCoach",
			func(ctx context.Context, req model.CoachRequest) (*model.CoachReply, error) {
				return replyAsCoach(ctx, g, models.Coach, req)
			}),
	}
}

// Analyze — разбор переписки по скриншоту.
func (s *Service) Analyze(ctx context.Context, req model.AnalysisRequest) (*model.ChatBreakdown, error) {
	return s.analyze.Run(ctx, req)
}

// OpeningLine — первая фраза для мэтча.
func (s *Service) OpeningLine(ctx context.Context, req model.OpeningLineRequest) (*model.OpeningLine, error) {
	return s.openingLine.Run(ctx, req)
}

// Coach — ответ коуча на новое сообщение.
func (s *Service) Coach(ctx context.Context, req model.CoachRequest) (*model.CoachReply, error) {
	return s.coach.Run(ctx, req)
}

// errNoAnswer — модель ответила, но без текста, который можно показать.
var errNoAnswer = errors.New("the model returned an empty answer")

//go:embed prompts/*.md
var prompts embed.FS

// Системные промпты: общие правила Cue и инструкция задачи. Тексты — в prompts/*.md.
var (
	analysisSystem    = systemPrompt("analysis")
	openingLineSystem = systemPrompt("opening_line")
	coachSystem       = systemPrompt("coach")
)

func systemPrompt(task string) string {
	return readPrompt("shared") + "\n\n" + readPrompt(task)
}

func readPrompt(name string) string {
	text, err := prompts.ReadFile("prompts/" + name + ".md")
	if err != nil {
		// Файлы вшиваются в бинарник при сборке: ошибка тут — опечатка в имени.
		panic(err)
	}
	return strings.TrimSpace(string(text))
}

package api

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/firebase/genkit/go/ai"
	"github.com/firebase/genkit/go/core/status"
	"github.com/gin-gonic/gin"

	"github.com/AgentChe/dating_assistant/server/model"
)

func TestMain(m *testing.M) {
	gin.SetMode(gin.TestMode)
	m.Run()
}

// fakeService — ИИ для тестов HTTP-слоя: отвечает заготовкой или ошибкой.
type fakeService struct {
	breakdown *model.ChatBreakdown
	line      *model.OpeningLine
	reply     *model.CoachReply
	err       error
	// wait — дождаться отмены контекста, как зависшая модель.
	wait bool
}

func (f *fakeService) result(ctx context.Context) error {
	if f.wait {
		<-ctx.Done()
		return ctx.Err()
	}
	return f.err
}

func (f *fakeService) Analyze(ctx context.Context, _ model.AnalysisRequest) (*model.ChatBreakdown, error) {
	return f.breakdown, f.result(ctx)
}

func (f *fakeService) OpeningLine(ctx context.Context, _ model.OpeningLineRequest) (*model.OpeningLine, error) {
	return f.line, f.result(ctx)
}

func (f *fakeService) Coach(ctx context.Context, _ model.CoachRequest) (*model.CoachReply, error) {
	return f.reply, f.result(ctx)
}

func post(t *testing.T, router http.Handler, path, body string) (int, map[string]any) {
	t.Helper()
	recorder := httptest.NewRecorder()
	router.ServeHTTP(recorder, httptest.NewRequest(http.MethodPost, path, strings.NewReader(body)))
	var answer map[string]any
	if err := json.Unmarshal(recorder.Body.Bytes(), &answer); err != nil {
		t.Fatalf("%s: the answer is not JSON: %q", path, recorder.Body.String())
	}
	return recorder.Code, answer
}

func errorMessage(body map[string]any) string {
	errorBody, _ := body["error"].(map[string]any)
	message, _ := errorBody["message"].(string)
	return message
}

// field — значение по пути: field(body, "partner", "name").
func field(body map[string]any, path ...string) any {
	var value any = body
	for _, name := range path {
		object, ok := value.(map[string]any)
		if !ok {
			return nil
		}
		value = object[name]
	}
	return value
}

var nikaBreakdown = &model.ChatBreakdown{
	Partner:   model.ChatPartner{Name: "Nika", Age: 28},
	Read:      model.ChatRead{Emoji: "😍", Verdict: "Nika is into this", Detail: "and doing most of the work."},
	Interest:  model.InterestPair{Them: model.InterestLevel{Level: 4, Label: "Warm"}, You: model.InterestLevel{Level: 3, Label: "Mixed"}},
	WordShare: model.WordShare{Them: 70, You: 30},
	GoingWell: []model.ChatSignal{{Title: "Asked about you", Proof: "“is that tent real…”"}},
	WatchOut:  []model.ChatSignal{{Title: "You didn’t ask back", Proof: "Your only reply"}},
	Topics:    []model.ChatTopic{{Emoji: "🏔️", Title: "Mountains"}, {Emoji: "⛺", Title: "The tent"}},
	Vibe:      model.VibePair{Them: model.ChatVibe{Emoji: "😜", Label: "Playful"}, You: model.ChatVibe{Emoji: "😌", Label: "Laid-back"}},
	Heading:   model.ChatHeading{Label: "Warming up", Trend: "up", Detail: "The last message is the most personal yet."},
	NextMove:  "Ask about the mountains.",
}

func TestAnalysisAnswersInTheShapeTheAppReads(t *testing.T) {
	router := NewRouter(&fakeService{breakdown: nikaBreakdown}, Options{})

	code, body := post(t, router, "/api/v1/analyses", `{"screenshot": "aGk="}`)

	if code != http.StatusOK {
		t.Fatalf("code %d: %v", code, body)
	}
	if id, _ := body["id"].(string); !strings.HasPrefix(id, "analysis-") {
		t.Errorf("id: %v", body["id"])
	}
	// Поля — те, что читает ChatBreakdown.fromJson в приложении.
	for path, want := range map[string]any{
		"partner.name":        "Nika",
		"partner.age":         28.0,
		"read.verdict":        "Nika is into this",
		"interest.them.level": 4.0,
		"interest.you.label":  "Mixed",
		"word_share.them":     70.0,
		"heading.trend":       "up",
		"next_move":           "Ask about the mountains.",
		"vibe.them.emoji":     "😜",
	} {
		if got := field(body, strings.Split(path, ".")...); got != want {
			t.Errorf("%s = %v, want %v", path, got, want)
		}
	}
	if signals, _ := body["going_well"].([]any); len(signals) != 1 || field(signals[0].(map[string]any), "proof") != "“is that tent real…”" {
		t.Errorf("going_well: %v", body["going_well"])
	}
}

func TestEmptyBrokenAndHugeRequestsAreRejected(t *testing.T) {
	router := NewRouter(&fakeService{breakdown: nikaBreakdown}, Options{MaxBodyBytes: 64})

	for _, test := range []struct {
		body    string
		code    int
		message string
	}{
		{`{"screenshot": " "}`, http.StatusBadRequest, "The screenshot is empty"},
		{`{"screenshot": `, http.StatusBadRequest, "The request is not valid JSON"},
		{`{"screenshot": "` + strings.Repeat("A", 100) + `"}`, http.StatusRequestEntityTooLarge, "The request is too large"},
	} {
		code, body := post(t, router, "/api/v1/analyses", test.body)
		if code != test.code || errorMessage(body) != test.message {
			t.Errorf("%.20s…: got %d %q, want %d %q", test.body, code, errorMessage(body), test.code, test.message)
		}
	}
}

func TestGenerationErrorsBecomeHTTPCodes(t *testing.T) {
	for _, test := range []struct {
		err  error
		code int
	}{
		{&model.InputError{Message: "The message is empty"}, http.StatusBadRequest},
		{status.Errorf(status.ErrInvalidInput, "invalid input to action"), http.StatusBadRequest},
		{fmt.Errorf("flow: %w", model.ErrNotAChat), http.StatusUnprocessableEntity},
		{ai.ErrGenerationBlocked, http.StatusUnprocessableEntity},
		{status.Errorf(status.ErrResourceExhausted, "quota"), http.StatusServiceUnavailable},
		{status.Errorf(status.ErrUnavailable, "overloaded"), http.StatusServiceUnavailable},
		{errors.New("something else"), http.StatusBadGateway},
	} {
		router := NewRouter(&fakeService{err: test.err}, Options{})
		code, body := post(t, router, "/api/v1/coach/messages", `{"text": "hi", "tone": "auto", "spice": "warm"}`)
		if code != test.code || errorMessage(body) == "" {
			t.Errorf("%v: got %d %v, want %d with a message", test.err, code, body, test.code)
		}
	}
}

func TestASlowModelIsCutOffBeforeTheAppGivesUp(t *testing.T) {
	router := NewRouter(&fakeService{wait: true}, Options{GenerationTimeout: 20 * time.Millisecond})

	code, body := post(t, router, "/api/v1/opening-lines", `{"spice": "warm"}`)

	if code != http.StatusGatewayTimeout || errorMessage(body) != "The AI took too long to answer" {
		t.Fatalf("got %d %v", code, body)
	}
}

func TestOpeningLineAndCoachAnswers(t *testing.T) {
	router := NewRouter(&fakeService{
		line: &model.OpeningLine{Line: "perfect sunday, go"},
		reply: &model.CoachReply{
			Text:         "Good instinct:",
			Suggestion:   &model.CoachSuggestion{Text: "coffee thursday?"},
			QuickReplies: []string{"Make it bolder"},
		},
	}, Options{})

	code, line := post(t, router, "/api/v1/opening-lines", `{"spice": "warm"}`)
	if code != http.StatusOK || line["line"] != "perfect sunday, go" || !strings.HasPrefix(line["id"].(string), "line-") {
		t.Errorf("opening line: %d %v", code, line)
	}
	// Без анкеты `match` нет совсем — приложение читает его как необязательное.
	if _, ok := line["match"]; ok {
		t.Errorf("match must be left out: %v", line)
	}

	code, reply := post(t, router, "/api/v1/coach/messages", `{"text": "Should I ask them out?", "tone": "auto", "spice": "warm"}`)
	if code != http.StatusOK || reply["text"] != "Good instinct:" || field(reply, "suggestion", "text") != "coffee thursday?" {
		t.Errorf("coach: %d %v", code, reply)
	}
	if _, ok := field(reply, "suggestion").(map[string]any)["why"]; ok {
		t.Errorf("an empty why must be left out: %v", reply)
	}
	if _, ok := reply["chat"]; ok {
		t.Errorf("chat must be left out: %v", reply)
	}
}

func TestUnknownPathsAnswerWithAnError(t *testing.T) {
	router := NewRouter(&fakeService{}, Options{})

	code, body := post(t, router, "/api/v1/usage", `{}`)
	if code != http.StatusNotFound || errorMessage(body) != "Not found" {
		t.Errorf("got %d %v", code, body)
	}

	recorder := httptest.NewRecorder()
	router.ServeHTTP(recorder, httptest.NewRequest(http.MethodGet, "/healthz", nil))
	if recorder.Code != http.StatusOK || recorder.Body.String() != "ok" {
		t.Errorf("healthz: %d %q", recorder.Code, recorder.Body.String())
	}
}

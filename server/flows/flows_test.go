package flows

import (
	"context"
	"encoding/base64"
	"errors"
	"slices"
	"strings"
	"testing"

	"github.com/firebase/genkit/go/ai"
	"github.com/firebase/genkit/go/genkit"

	"github.com/AgentChe/dating_assistant/server/model"
)

// Настоящая картинка 1×1 PNG — та же, что в тестах приложения.
const pngScreenshot = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="

// fakeModel отдаёт заготовленный JSON и запоминает, что у неё спросили.
type fakeModel struct {
	reply   string
	request *ai.ModelRequest
}

func newService(t *testing.T, reply string) (*Service, *fakeModel) {
	t.Helper()
	g := genkit.Init(context.Background())
	fake := &fakeModel{reply: reply}
	m := genkit.DefineModelAction(g, "fake/model", &ai.ModelOptions{
		Supports: &ai.ModelSupports{Media: true, Multiturn: true, SystemRole: true, Constrained: ai.ConstrainedSupportAll},
	}, func(ctx context.Context, req *ai.ModelRequest, _ struct{}, _ ai.ModelStreamCallback) (*ai.ModelResponse, error) {
		fake.request = req
		return &ai.ModelResponse{Message: ai.NewModelTextMessage(fake.reply), FinishReason: ai.FinishReasonStop}, nil
	})
	return New(g, Models{Analysis: m, OpeningLine: m, Coach: m}), fake
}

func (f *fakeModel) message(role ai.Role) *ai.Message {
	for _, message := range f.request.Messages {
		if message.Role == role {
			return message
		}
	}
	return nil
}

func (f *fakeModel) systemText() string { return f.message(ai.RoleSystem).Text() }

func (f *fakeModel) userText() string { return f.message(ai.RoleUser).Text() }

func (f *fakeModel) images() []*ai.Part {
	var images []*ai.Part
	for _, part := range f.message(ai.RoleUser).Content {
		if part.IsMedia() {
			images = append(images, part)
		}
	}
	return images
}

// required — обязательные поля схемы ответа по пути вложенных объектов: required("breakdown", "partner").
func (f *fakeModel) required(path ...string) []string {
	schema := f.request.Output.Schema
	for _, name := range path {
		schema = schema["properties"].(map[string]any)[name].(map[string]any)
	}
	var names []string
	if required, ok := schema["required"].([]any); ok {
		for _, name := range required {
			names = append(names, name.(string))
		}
	}
	if required, ok := schema["required"].([]string); ok {
		names = required
	}
	slices.Sort(names)
	return names
}

func expectContains(t *testing.T, text string, parts ...string) {
	t.Helper()
	for _, part := range parts {
		if !strings.Contains(text, part) {
			t.Errorf("expected %q in:\n%s", part, text)
		}
	}
}

const breakdownReply = `{"is_chat": true, "breakdown": {
	"partner": {"name": " Nika ", "age": 28},
	"read": {"emoji": "😍", "verdict": "Nika is into this", "detail": "and doing most of the work."},
	"interest": {"them": {"level": 4, "label": "Hot"}, "you": {"level": 3, "label": "Mixed"}},
	"word_share": {"them": 7, "you": 3},
	"going_well": [{"title": "Asked about you", "proof": "“is that tent real…”"}, {"title": " ", "proof": "skip me"}],
	"watch_out": [{"title": "You didn’t ask back", "proof": "Your only reply"}],
	"topics": [{"emoji": "🏔️", "title": "Mountains"}, {"emoji": "⛺", "title": "The tent"}],
	"vibe": {"them": {"emoji": "😜", "label": "Playful"}, "you": {"emoji": "😌", "label": "Laid-back"}},
	"heading": {"label": "Warming up", "trend": "up", "detail": "The last message is the most personal yet."},
	"next_move": "Ask about the mountains."}}`

func TestAnalyzeSendsTheScreenshotAndTidiesTheBreakdown(t *testing.T) {
	service, fake := newService(t, breakdownReply)

	breakdown, err := service.Analyze(context.Background(), model.AnalysisRequest{Screenshot: pngScreenshot})
	if err != nil {
		t.Fatal(err)
	}

	expectContains(t, fake.systemText(), "You are Cue", "Task: read the screenshot of a chat")
	images := fake.images()
	if len(images) != 1 || images[0].ContentType != "image/png" || images[0].Text != "data:image/png;base64,"+pngScreenshot {
		t.Fatalf("expected the screenshot as one PNG part, got %+v", images)
	}

	if breakdown.Partner != (model.ChatPartner{Name: "Nika", Age: 28}) {
		t.Errorf("partner: %+v", breakdown.Partner)
	}
	// Подпись — по уровню, как в макете: 4 — Warm.
	if breakdown.Interest.Them != (model.InterestLevel{Level: 4, Label: "Warm"}) {
		t.Errorf("their interest: %+v", breakdown.Interest.Them)
	}
	if breakdown.WordShare != (model.WordShare{Them: 70, You: 30}) {
		t.Errorf("word share: %+v", breakdown.WordShare)
	}
	if len(breakdown.GoingWell) != 1 || breakdown.GoingWell[0].Title != "Asked about you" {
		t.Errorf("going well: %+v", breakdown.GoingWell)
	}
	if got := fake.required("breakdown", "partner"); !slices.Equal(got, []string{"name"}) {
		t.Errorf("the age must stay optional, required: %v", got)
	}
}

func TestAnalyzeRefusesWhatIsNotAChat(t *testing.T) {
	service, _ := newService(t, `{"is_chat": false}`)

	_, err := service.Analyze(context.Background(), model.AnalysisRequest{Screenshot: pngScreenshot})
	if !errors.Is(err, model.ErrNotAChat) {
		t.Fatalf("expected ErrNotAChat, got %v", err)
	}
}

func TestAnalyzeRejectsWhatIsNotAnImage(t *testing.T) {
	service, fake := newService(t, breakdownReply)

	for _, screenshot := range []string{"not base64!", base64.StdEncoding.EncodeToString([]byte("just some text"))} {
		_, err := service.Analyze(context.Background(), model.AnalysisRequest{Screenshot: screenshot})
		var input *model.InputError
		if !errors.As(err, &input) {
			t.Errorf("%q: expected an input error, got %v", screenshot, err)
		}
	}
	if fake.request != nil {
		t.Error("the model must not be asked about a broken screenshot")
	}
}

func TestOpeningLineIsWrittenForTheUserAndTheMatch(t *testing.T) {
	service, fake := newService(t, `{"line": "“teach me climbing?”", "match": {"name": "Sam"}}`)

	line, err := service.OpeningLine(context.Background(), model.OpeningLineRequest{
		Spice:         "bold",
		You:           &model.You{Gender: "man", AgeRange: "from25To34", Goal: "relationship", Voice: []string{"lowercase", "emoji"}},
		Match:         &model.MatchDetails{Name: "Sam", Interests: "climbing"},
		PreviousLines: []string{"first line", " "},
	})
	if err != nil {
		t.Fatal(err)
	}

	expectContains(t, fake.userText(),
		"Spice: 4 of 5 (bold).",
		"- a man, aged 25–34, looking for a relationship",
		"keep messages to send lowercase",
		"uses emoji",
		"- name: Sam\n- interests: climbing",
		"Lines you already suggested — write something different:\n- first line\n\n",
	)
	if len(fake.images()) != 0 {
		t.Error("no profile screenshot was sent")
	}
	// Кавычки вокруг фразы сняты; без скриншота анкеты `match` не возвращается.
	if line.Line != "teach me climbing?" || line.Match != nil {
		t.Errorf("unexpected line: %+v", line)
	}
	if got := fake.required(); !slices.Equal(got, []string{"line"}) {
		t.Errorf("only the line is required, got %v", got)
	}
}

func TestOpeningLineReadsTheProfileScreenshot(t *testing.T) {
	service, fake := newService(t, `{"line": "fair. what brings you down here?", "match": {"name": " Nika ", "age": 28, "interests": "mountains"}}`)

	line, err := service.OpeningLine(context.Background(), model.OpeningLineRequest{Spice: "warm", ProfileScreenshot: pngScreenshot})
	if err != nil {
		t.Fatal(err)
	}

	expectContains(t, fake.userText(), "Spice: 2 of 5 (warm).", "The match's profile screenshot is attached.", "nothing is known")
	if len(fake.images()) != 1 {
		t.Error("the profile screenshot must reach the model")
	}
	if line.Match == nil || *line.Match != (model.MatchDetails{Name: "Nika", Age: 28, Interests: "mountains"}) {
		t.Errorf("unexpected match: %+v", line.Match)
	}
}

func TestCoachNeedsAMessageUnlessAChatIsShared(t *testing.T) {
	service, fake := newService(t, `{"text": "Here’s my read:", "quick_replies": []}`)

	_, err := service.Coach(context.Background(), model.CoachRequest{Tone: "auto", Spice: "warm", Text: "  "})
	var input *model.InputError
	if !errors.As(err, &input) || input.Message != "The message is empty" {
		t.Fatalf("expected «The message is empty», got %v", err)
	}
	if fake.request != nil {
		t.Fatal("the model must not be asked about an empty message")
	}

	// «Get the next message» из разбора: текста нет, но есть разбор, о котором коуч ещё ничего не сказал.
	breakdown := map[string]any{"partner": map[string]any{"name": "Nika"}}
	if _, err := service.Coach(context.Background(), model.CoachRequest{Tone: "auto", Spice: "warm", Breakdown: breakdown}); err != nil {
		t.Fatal(err)
	}
	expectContains(t, fake.userText(), `Your breakdown of this chat:`+"\n"+`{"partner":{"name":"Nika"}}`, "The user sent no text")
}

func TestCoachGetsTheWholeConversation(t *testing.T) {
	service, fake := newService(t, `{
		"text": " Bolder it is: ",
		"suggestion": {"text": "\"let’s take this offline. thursday?\"", "why": "Direct and easy to say yes to."},
		"quick_replies": ["Give me another option", " ", "What if there’s no reply?"],
		"chat": {"name": "Nika"}}`)

	reply, err := service.Coach(context.Background(), model.CoachRequest{
		Text:  "Make it bolder",
		Tone:  "intrigue",
		Spice: "playful",
		Messages: []model.CoachMessage{
			{From: "you", Text: "Should I ask them out?"},
			{From: "coach", Text: "Good instinct.", Suggestion: &model.CoachSuggestion{Text: "coffee thursday?"}},
		},
		Chat: &model.AttachedChat{Name: "Nika", Age: 28, Verdict: "Nika is into this — and doing most of the work."},
	})
	if err != nil {
		t.Fatal(err)
	}

	expectContains(t, fake.userText(),
		"Tone: intrigue. Spice: 3 of 5 (playful).",
		"The chat you are talking about is with Nika, 28. Your read of it: Nika is into this",
		"User: Should I ask them out?\nCue: Good instinct.\nCue suggested sending: coffee thursday?",
		"don't suggest them again:\n- coffee thursday?",
		"The user's new message:\nMake it bolder",
	)
	if reply.Text != "Bolder it is:" || reply.Suggestion.Text != "let’s take this offline. thursday?" {
		t.Errorf("unexpected reply: %+v %+v", reply, reply.Suggestion)
	}
	if !slices.Equal(reply.QuickReplies, []string{"Give me another option", "What if there’s no reply?"}) {
		t.Errorf("quick replies: %q", reply.QuickReplies)
	}
	// О прежней переписке приложение знает само: карточка приходит только с новым скриншотом.
	if reply.Chat != nil {
		t.Errorf("chat without a screenshot: %+v", reply.Chat)
	}
	if got := fake.required(); !slices.Equal(got, []string{"quick_replies", "text"}) {
		t.Errorf("suggestion and chat must stay optional, required: %v", got)
	}
}

func TestCoachReadsANewChatScreenshot(t *testing.T) {
	service, fake := newService(t, `{"text": "I read your chat:", "quick_replies": ["Make it bolder"], "chat": {"name": " ", "verdict": " They’re curious. "}}`)

	reply, err := service.Coach(context.Background(), model.CoachRequest{Tone: "auto", Spice: "spicy", ChatScreenshot: pngScreenshot})
	if err != nil {
		t.Fatal(err)
	}

	expectContains(t, fake.userText(), "The user attached a new screenshot", "The user sent no text")
	if len(fake.images()) != 1 {
		t.Error("the chat screenshot must reach the model")
	}
	if reply.Chat == nil || *reply.Chat != (model.AttachedChat{Name: "Your match", Verdict: "They’re curious."}) {
		t.Errorf("unexpected chat: %+v", reply.Chat)
	}
}

func TestTidyingWhatTheSchemaCannotCheck(t *testing.T) {
	for _, test := range []struct{ them, you, wantThem, wantYou int }{
		{0, 0, 50, 50}, {1, 2, 33, 67}, {200, 0, 100, 0},
	} {
		got := tidyWordShare(model.WordShare{Them: test.them, You: test.you})
		if got.Them != test.wantThem || got.You != test.wantYou {
			t.Errorf("word share %d/%d → %+v", test.them, test.you, got)
		}
	}

	for level, want := range map[int]model.InterestLevel{0: {Level: 1, Label: "Cold"}, 9: {Level: 5, Label: "Hot"}} {
		interest := model.InterestLevel{Level: level, Label: "Mixed"}
		if tidyInterest(&interest); interest != want {
			t.Errorf("interest %d → %+v", level, interest)
		}
	}

	for message, want := range map[string]string{
		` "hi there" `: "hi there", "«привет»": "привет", "it's 'fine'": "it's 'fine'", `"`: `"`,
	} {
		if got := tidyMessage(message); got != want {
			t.Errorf("tidyMessage(%q) = %q, want %q", message, got, want)
		}
	}

	for data, want := range map[string]string{
		"\xff\xd8\xff\xe0 jpeg":           "image/jpeg",
		"\x00\x00\x00\x18ftypheic heic":   "image/heic",
		"GIF89a not supported by the app": "",
	} {
		if got := imageType([]byte(data)); got != want {
			t.Errorf("imageType(%q) = %q, want %q", data, got, want)
		}
	}
}

func TestNamesWithTheModelsReasoningInsideAreCut(t *testing.T) {
	for name, want := range map[string]string{
		"Sam":        "Sam",
		" Mary Ann ": "Mary Ann",
		"Nika, 28":   "Nika, 28",
		"Sam customer profile name is Sam, age 27, interests climbing, coffee, tacos, live music, message 'Weekend climber' or similar. Let's strictly follow schema guidelines and provide concise data:": "Sam",
		"The match's name is not visible on the screenshot, so the user should ask": "",
		"name: unknown": "",
		"":              "",
	} {
		if got := tidyName(name); got != want {
			t.Errorf("tidyName(%q) = %q, want %q", name, got, want)
		}
	}
	if got := shortOrEmpty(strings.Repeat("climbing, ", 30), 160); got != "" {
		t.Errorf("an overlong field must be dropped, got %q", got)
	}
}

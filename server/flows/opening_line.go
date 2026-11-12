package flows

import (
	"context"
	"strings"
	"unicode/utf8"

	"github.com/firebase/genkit/go/ai"
	"github.com/firebase/genkit/go/genkit"

	"github.com/AgentChe/dating_assistant/server/model"
)

// writeOpeningLine — первая фраза для мэтча. Со скриншотом анкеты модель ещё и возвращает, что в ней прочитала.
func writeOpeningLine(ctx context.Context, g *genkit.Genkit, m ai.ModelArg, req model.OpeningLineRequest) (*model.OpeningLine, error) {
	hasProfile := strings.TrimSpace(req.ProfileScreenshot) != ""
	parts := []*ai.Part{ai.NewTextPart(describeOpeningLineRequest(req, hasProfile))}
	if hasProfile {
		profile, err := imagePart("profile screenshot", req.ProfileScreenshot)
		if err != nil {
			return nil, err
		}
		parts = append(parts, profile)
	}

	out, _, err := genkit.GenerateData[model.OpeningLine](ctx, g,
		ai.WithModel(m),
		ai.WithSystem(openingLineSystem),
		ai.WithMessages(ai.NewUserMessage(parts...)),
	)
	if err != nil {
		return nil, err
	}
	if out == nil {
		return nil, errNoAnswer
	}
	if out.Line = tidyMessage(out.Line); out.Line == "" {
		return nil, errNoAnswer
	}
	// Анкету сервер читает только со скриншота: без него `match` приложению не нужен.
	out.Match = tidyMatch(out.Match)
	if !hasProfile {
		out.Match = nil
	}
	return out, nil
}

// tidyMatch — прочитанное в анкете без пустых полей; ничего не прочитано — nil.
func tidyMatch(match *model.MatchDetails) *model.MatchDetails {
	if match == nil {
		return nil
	}
	tidy := model.MatchDetails{
		Name:      strings.TrimSpace(match.Name),
		Age:       plausibleAge(match.Age),
		Message:   strings.TrimSpace(match.Message),
		Interests: strings.TrimSpace(match.Interests),
	}
	if tidy == (model.MatchDetails{}) {
		return nil
	}
	return &tidy
}

// quotePairs — кавычки, в которые модель иногда заворачивает готовое сообщение.
var quotePairs = map[rune]rune{'"': '"', '“': '”', '«': '»', '\'': '\''}

// tidyMessage — сообщение без пробелов по краям и без кавычек вокруг.
func tidyMessage(message string) string {
	message = strings.TrimSpace(message)
	first, size := utf8.DecodeRuneInString(message)
	last, lastSize := utf8.DecodeLastRuneInString(message)
	if closing, ok := quotePairs[first]; ok && last == closing && len(message) > size+lastSize {
		message = strings.TrimSpace(message[size : len(message)-lastSize])
	}
	return message
}

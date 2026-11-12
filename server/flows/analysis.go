package flows

import (
	"context"
	"slices"
	"strings"

	"github.com/firebase/genkit/go/ai"
	"github.com/firebase/genkit/go/genkit"

	"github.com/AgentChe/dating_assistant/server/model"
)

// analysisOutput — ответ модели: переписка ли это вообще и, если да, её разбор.
type analysisOutput struct {
	IsChat    bool                 `json:"is_chat" jsonschema_description:"True if the image is a readable text conversation between the user and a match."`
	Breakdown *model.ChatBreakdown `json:"breakdown,omitempty" jsonschema_description:"The breakdown. Required when is_chat is true."`
}

// Подписи шкалы интереса по уровню — как в макете: 3 — Mixed, 4 — Warm.
var interestLabels = [...]string{"Cold", "Cool", "Mixed", "Warm", "Hot"}

// analyzeChat — разбор переписки по скриншоту. Не переписка — model.ErrNotAChat.
func analyzeChat(ctx context.Context, g *genkit.Genkit, m ai.ModelArg, req model.AnalysisRequest) (*model.ChatBreakdown, error) {
	screenshot, err := imagePart("screenshot", req.Screenshot)
	if err != nil {
		return nil, err
	}

	out, _, err := genkit.GenerateData[analysisOutput](ctx, g,
		ai.WithModel(m),
		ai.WithSystem(analysisSystem),
		ai.WithMessages(ai.NewUserMessage(ai.NewTextPart("Break down this chat."), screenshot)),
	)
	if err != nil {
		return nil, err
	}
	if out == nil {
		return nil, errNoAnswer
	}
	if !out.IsChat || out.Breakdown == nil {
		return nil, model.ErrNotAChat
	}
	tidyBreakdown(out.Breakdown)
	return out.Breakdown, nil
}

// tidyBreakdown страхует то, что схема не проверит: подпись под уровнем, сумму долей, длину списков.
func tidyBreakdown(b *model.ChatBreakdown) {
	b.Partner.Name = orDefault(b.Partner.Name, unknownMatch)
	b.Partner.Age = plausibleAge(b.Partner.Age)
	tidyInterest(&b.Interest.Them)
	tidyInterest(&b.Interest.You)
	b.WordShare = tidyWordShare(b.WordShare)
	b.GoingWell = tidySignals(b.GoingWell)
	b.WatchOut = tidySignals(b.WatchOut)

	topics := make([]model.ChatTopic, 0, len(b.Topics))
	for _, topic := range b.Topics {
		if title := strings.TrimSpace(topic.Title); title != "" && len(topics) < 3 {
			topics = append(topics, model.ChatTopic{Emoji: strings.TrimSpace(topic.Emoji), Title: title})
		}
	}
	b.Topics = topics

	if !slices.Contains([]string{"up", "flat", "down"}, b.Heading.Trend) {
		b.Heading.Trend = "flat"
	}
	b.Read.Verdict = strings.TrimSpace(b.Read.Verdict)
	b.Read.Detail = strings.TrimSpace(b.Read.Detail)
	b.NextMove = strings.TrimSpace(b.NextMove)
}

func tidyInterest(interest *model.InterestLevel) {
	interest.Level = min(max(interest.Level, 1), len(interestLabels))
	interest.Label = interestLabels[interest.Level-1]
}

// tidyWordShare — доли в процентах, в сумме ровно 100.
func tidyWordShare(share model.WordShare) model.WordShare {
	them, you := max(share.Them, 0), max(share.You, 0)
	if them+you == 0 {
		return model.WordShare{Them: 50, You: 50}
	}
	them = (them*100 + (them+you)/2) / (them + you)
	return model.WordShare{Them: them, You: 100 - them}
}

func tidySignals(signals []model.ChatSignal) []model.ChatSignal {
	result := make([]model.ChatSignal, 0, len(signals))
	for _, signal := range signals {
		title, proof := strings.TrimSpace(signal.Title), strings.TrimSpace(signal.Proof)
		if title != "" && len(result) < 3 {
			result = append(result, model.ChatSignal{Title: title, Proof: proof})
		}
	}
	return result
}

// plausibleAge — возраст, если он похож на правду, иначе 0 (в ответе поля не будет).
func plausibleAge(age int) int {
	if age < 1 || age > 120 {
		return 0
	}
	return age
}

func orDefault(value, fallback string) string {
	if value = strings.TrimSpace(value); value != "" {
		return value
	}
	return fallback
}

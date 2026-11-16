package flows

import (
	"context"
	"strings"

	"github.com/firebase/genkit/go/ai"
	"github.com/firebase/genkit/go/genkit"

	"github.com/AgentChe/dating_assistant/server/model"
)

// replyAsCoach — ответ коуча. Сервер разговор не помнит: история, переписка и разбор приходят в запросе.
func replyAsCoach(ctx context.Context, g *genkit.Genkit, m ai.ModelArg, req model.CoachRequest) (*model.CoachReply, error) {
	hasScreenshot := strings.TrimSpace(req.ChatScreenshot) != ""
	// Разговор о переписке начинается со скриншота или с разбора, о котором коуч ещё ничего не сказал, — тогда
	// текст не нужен. В остальных случаях пустое сообщение — ошибка приложения.
	startsWithChat := hasScreenshot || (req.Breakdown != nil && len(req.Messages) == 0)
	if strings.TrimSpace(req.Text) == "" && !startsWithChat {
		return nil, &model.InputError{Message: "The message is empty"}
	}

	parts := []*ai.Part{ai.NewTextPart(describeCoachRequest(req, hasScreenshot))}
	if hasScreenshot {
		screenshot, err := imagePart("chat screenshot", req.ChatScreenshot)
		if err != nil {
			return nil, err
		}
		parts = append(parts, screenshot)
	}

	out, _, err := genkit.GenerateData[model.CoachReply](ctx, g,
		ai.WithModel(m),
		ai.WithSystem(coachSystem),
		ai.WithMessages(ai.NewUserMessage(parts...)),
	)
	if err != nil {
		return nil, err
	}
	if out == nil {
		return nil, errNoAnswer
	}
	if out.Text = strings.TrimSpace(out.Text); out.Text == "" {
		return nil, errNoAnswer
	}
	tidyCoachReply(out, hasScreenshot)
	return out, nil
}

func tidyCoachReply(reply *model.CoachReply, hasScreenshot bool) {
	if suggestion := reply.Suggestion; suggestion != nil {
		suggestion.Text = tidyMessage(suggestion.Text)
		suggestion.Why = strings.TrimSpace(suggestion.Why)
		if suggestion.Text == "" {
			reply.Suggestion = nil
		}
	}

	quickReplies := make([]string, 0, 3)
	for _, quickReply := range nonEmpty(reply.QuickReplies) {
		if len(quickReplies) < 3 {
			quickReplies = append(quickReplies, quickReply)
		}
	}
	reply.QuickReplies = quickReplies

	// Карточка «Chat attached» — только о новом скриншоте: о прежней переписке приложение уже знает.
	if chat := reply.Chat; chat != nil && hasScreenshot {
		chat.Name = orDefault(tidyName(chat.Name), unknownMatch)
		chat.Age = plausibleAge(chat.Age)
		// Просили до 10 слов: заметно длиннее — не вывод, а рассуждения, карточка обойдётся без него.
		chat.Verdict = shortOrEmpty(chat.Verdict, 120)
	} else {
		reply.Chat = nil
	}
}

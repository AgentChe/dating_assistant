// Package model — запросы и ответы API в том виде, в каком их шлёт и читает приложение
// (lib/service/*/request и lib/service/*/model). Имена полей — контракт: менять их можно только вместе с приложением.
package model

// You — блок `you`: ответы пользователя с онбординга (Profile.toRequestJson). Под них ИИ подстраивает голос.
type You struct {
	// man | woman | nonBinary
	Gender string `json:"gender"`
	// from18To24 | from25To34 | from35To44 | from45
	AgeRange string `json:"age_range"`
	// relationship | casual | friends | unsure
	Goal string `json:"goal"`
	// Черты стиля переписки: lowercase, emoji, direct.
	Voice []string `json:"voice"`
}

// AnalysisRequest — POST /api/v1/analyses.
type AnalysisRequest struct {
	// Скриншот переписки, base64.
	Screenshot string `json:"screenshot"`
}

// OpeningLineRequest — POST /api/v1/opening-lines.
type OpeningLineRequest struct {
	// soft | warm | playful | bold | spicy
	Spice string `json:"spice"`
	You   *You   `json:"you,omitempty"`
	// Что пользователь ввёл о мэтче сам («Type it out») или что сервер прочитал в анкете раньше.
	Match *MatchDetails `json:"match,omitempty"`
	// Скриншот анкеты, base64: сервер прочитает её и вернёт прочитанное в `match`.
	ProfileScreenshot string `json:"profile_screenshot,omitempty"`
	// Уже предложенные фразы — новая не должна их повторять.
	PreviousLines []string `json:"previous_lines,omitempty"`
}

// CoachRequest — POST /api/v1/coach/messages. Сервер разговоров не помнит: всё прошлое приходит в запросе.
type CoachRequest struct {
	// Новое сообщение пользователя; пустое — он только приложил переписку.
	Text string `json:"text,omitempty"`
	// auto | flirt | intrigue | connect
	Tone string `json:"tone"`
	// soft | warm | playful | bold | spicy
	Spice string `json:"spice"`
	You   *You   `json:"you,omitempty"`
	// Разговор до этого сообщения, по порядку.
	Messages []CoachMessage `json:"messages,omitempty"`
	// Переписка, о которой разговор: с кем и главный вывод.
	Chat *AttachedChat `json:"chat,omitempty"`
	// Разбор, из которого открыли коуча («Get the next message»), — тот JSON, что вернул POST /api/v1/analyses.
	// Коучу он нужен только как контекст, поэтому не разбирается по полям.
	Breakdown map[string]any `json:"breakdown,omitempty"`
	// Новый скриншот переписки, base64: сервер прочитает его и вернёт карточку в `chat`.
	ChatScreenshot string `json:"chat_screenshot,omitempty"`
}

// CoachMessage — сообщение в разговоре с коучем.
type CoachMessage struct {
	// you | coach
	From string `json:"from"`
	// Пусто у сообщения пользователя, который приложил только скриншот.
	Text       string           `json:"text,omitempty"`
	Suggestion *CoachSuggestion `json:"suggestion,omitempty"`
}

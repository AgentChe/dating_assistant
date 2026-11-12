package model

// Ответы без `id`: id добавляет API. Эти же структуры — схема ответа модели, поэтому описания полей
// (jsonschema_description) написаны для неё. Поле без omitempty модель обязана заполнить.

// ChatBreakdown — разбор переписки (ChatBreakdown.fromJson в приложении). «Them» — мэтч, «you» — пользователь.
type ChatBreakdown struct {
	Partner   ChatPartner  `json:"partner"`
	Read      ChatRead     `json:"read"`
	Interest  InterestPair `json:"interest"`
	WordShare WordShare    `json:"word_share"`
	GoingWell []ChatSignal `json:"going_well" jsonschema:"minItems=1,maxItems=3" jsonschema_description:"Good signs in the chat."`
	WatchOut  []ChatSignal `json:"watch_out" jsonschema:"minItems=1,maxItems=3" jsonschema_description:"Things the user should change, said to the user."`
	Topics    []ChatTopic  `json:"topics" jsonschema:"minItems=2,maxItems=3" jsonschema_description:"Things worth talking about next, taken from the chat."`
	Vibe      VibePair     `json:"vibe"`
	Heading   ChatHeading  `json:"heading"`
	NextMove  string       `json:"next_move" jsonschema_description:"What to do next: one or two short sentences, up to 20 words. Advice, not a ready-made message."`
}

// ChatPartner — с кем переписка.
type ChatPartner struct {
	Name string `json:"name" jsonschema_description:"The match's name as shown in the chat, or Your match."`
	Age  int    `json:"age,omitempty" jsonschema_description:"The match's age, only if it is shown."`
}

// ChatRead — главный вывод: «😍 Nika is into this — and doing most of the work.».
type ChatRead struct {
	Emoji   string `json:"emoji" jsonschema_description:"One emoji for the overall read."`
	Verdict string `json:"verdict" jsonschema_description:"Up to 5 words, starting with the match's name when known."`
	Detail  string `json:"detail" jsonschema_description:"3 to 8 words continuing the verdict, starting lowercase, ending with a period."`
}

// InterestPair — интерес каждой стороны.
type InterestPair struct {
	Them InterestLevel `json:"them"`
	You  InterestLevel `json:"you"`
}

// InterestLevel — интерес по шкале 1–5: «Warm», 4 из 5.
type InterestLevel struct {
	Level int    `json:"level" jsonschema:"minimum=1,maximum=5"`
	Label string `json:"label" jsonschema:"enum=Cold,enum=Cool,enum=Mixed,enum=Warm,enum=Hot" jsonschema_description:"Matches the level: 1 Cold, 2 Cool, 3 Mixed, 4 Warm, 5 Hot."`
}

// WordShare — доля слов каждой стороны в процентах, в сумме 100.
type WordShare struct {
	Them int `json:"them" jsonschema:"minimum=0,maximum=100"`
	You  int `json:"you" jsonschema:"minimum=0,maximum=100"`
}

// ChatSignal — наблюдение с доказательством: «Asked about you» — «“is that tent real…”».
type ChatSignal struct {
	Title string `json:"title" jsonschema_description:"2 to 4 words."`
	Proof string `json:"proof" jsonschema_description:"A short quote from the chat in curly quotes, cut with an ellipsis, or a short fact."`
}

// ChatTopic — тема для разговора: «🏔️ Mountains».
type ChatTopic struct {
	Emoji string `json:"emoji"`
	Title string `json:"title" jsonschema_description:"1 to 3 words."`
}

// VibePair — манера переписки каждой стороны.
type VibePair struct {
	Them ChatVibe `json:"them"`
	You  ChatVibe `json:"you"`
}

// ChatVibe — манера переписки: «😜 Playful».
type ChatVibe struct {
	Emoji string `json:"emoji"`
	Label string `json:"label" jsonschema_description:"One word."`
}

// ChatHeading — куда идёт переписка: «Warming up ↗».
type ChatHeading struct {
	Label  string `json:"label" jsonschema_description:"1 to 3 words."`
	Trend  string `json:"trend" jsonschema:"enum=up,enum=flat,enum=down"`
	Detail string `json:"detail" jsonschema_description:"One sentence, up to 12 words."`
}

// OpeningLine — первая фраза для мэтча (OpeningLine.fromJson в приложении).
type OpeningLine struct {
	Line  string        `json:"line" jsonschema_description:"The opening message in the user's voice, ready to send."`
	Match *MatchDetails `json:"match,omitempty" jsonschema_description:"What you read on the match's profile screenshot. Only when a readable profile screenshot is attached."`
}

// MatchDetails — что известно о мэтче: из анкеты на скриншоте или со слов пользователя.
type MatchDetails struct {
	Name      string `json:"name,omitempty" jsonschema_description:"The match's first name."`
	Age       int    `json:"age,omitempty" jsonschema_description:"The match's age, only if it is shown."`
	Message   string `json:"message,omitempty" jsonschema_description:"Something the match wrote that is worth replying to, as written, up to 120 characters."`
	Interests string `json:"interests,omitempty" jsonschema_description:"Up to five interests from the profile, comma-separated."`
}

// CoachReply — ответ коуча (CoachReply.fromJson в приложении).
type CoachReply struct {
	Text         string           `json:"text" jsonschema_description:"Your advice to the user: 1 to 3 short sentences. Ends with a colon when a suggestion follows."`
	Suggestion   *CoachSuggestion `json:"suggestion,omitempty" jsonschema_description:"A message to send. Leave out when a ready-made message doesn't fit."`
	QuickReplies []string         `json:"quick_replies" jsonschema:"maxItems=3" jsonschema_description:"2 or 3 follow-ups the user may tap next, up to 4 words each, in the user's words."`
	Chat         *AttachedChat    `json:"chat,omitempty" jsonschema_description:"The chat on the attached screenshot. Only when a new chat screenshot is attached."`
}

// CoachSuggestion — готовое сообщение «Try sending».
type CoachSuggestion struct {
	Text string `json:"text" jsonschema_description:"The message to send, in the user's voice."`
	Why  string `json:"why,omitempty" jsonschema_description:"Why it works, one short sentence."`
}

// AttachedChat — карточка «Chat attached»: с кем переписка и главный вывод.
type AttachedChat struct {
	Name    string `json:"name" jsonschema_description:"The match's name, or Your match."`
	Age     int    `json:"age,omitempty" jsonschema_description:"The match's age, only if it is shown."`
	Verdict string `json:"verdict,omitempty" jsonschema_description:"Your read of the chat in up to 10 words."`
}

package flows

import (
	"encoding/json"
	"fmt"
	"slices"
	"strings"

	"github.com/AgentChe/dating_assistant/server/model"
)

// Текст запроса для модели: кто пользователь, острота, тон и всё, что известно о мэтче и о разговоре.

var (
	genders   = map[string]string{"man": "a man", "woman": "a woman", "nonBinary": "non-binary"}
	ageRanges = map[string]string{"from18To24": "18–24", "from25To34": "25–34", "from35To44": "35–44", "from45": "45 or older"}
	goals     = map[string]string{"relationship": "a relationship", "casual": "something casual", "friends": "new friends", "unsure": "not sure yet"}
	spices    = []string{"soft", "warm", "playful", "bold", "spicy"}
	tones     = []string{"auto", "flirt", "intrigue", "connect"}
)

// unknownMatch — имя мэтча, если его не видно.
const unknownMatch = "Your match"

// describeYou — блок «About the user»: под него модель пишет голосом пользователя.
func describeYou(you *model.You) string {
	lines := []string{"About the user:"}
	if you == nil {
		return strings.Join(append(lines, "- nothing is known: write in a natural, friendly texting style"), "\n")
	}

	var facts []string
	if gender := genders[you.Gender]; gender != "" {
		facts = append(facts, gender)
	}
	if age := ageRanges[you.AgeRange]; age != "" {
		facts = append(facts, "aged "+age)
	}
	if goal := goals[you.Goal]; goal != "" {
		facts = append(facts, "looking for "+goal)
	}
	if len(facts) > 0 {
		lines = append(lines, "- "+strings.Join(facts, ", "))
	}

	if slices.Contains(you.Voice, "lowercase") {
		lines = append(lines, "- writes in all lowercase: keep messages to send lowercase")
	} else {
		lines = append(lines, "- writes with normal capitalization")
	}
	if slices.Contains(you.Voice, "emoji") {
		lines = append(lines, "- uses emoji: one can fit naturally, never more than one")
	} else {
		lines = append(lines, "- rarely uses emoji: leave them out")
	}
	if slices.Contains(you.Voice, "direct") {
		lines = append(lines, "- is direct: gets to the point, no long build-ups")
	}
	if you.Goal == "friends" {
		lines = append(lines, "- is looking for friends: keep messages platonic, no flirting, whatever the spice")
	}
	return strings.Join(lines, "\n")
}

// describeSpice — «Spice: 3 of 5 (playful).». Незнакомое значение — warm, как в приложении по умолчанию.
func describeSpice(spice string) string {
	index := slices.Index(spices, spice)
	if index < 0 {
		index = 1
	}
	return fmt.Sprintf("Spice: %d of 5 (%s).", index+1, spices[index])
}

// describeTone — «Tone: intrigue.». Незнакомое значение — auto.
func describeTone(tone string) string {
	if !slices.Contains(tones, tone) {
		tone = "auto"
	}
	return "Tone: " + tone + "."
}

// describeMatch — что пользователь знает о мэтче.
func describeMatch(match *model.MatchDetails) string {
	if match == nil {
		return ""
	}
	var facts []string
	if name := strings.TrimSpace(match.Name); name != "" {
		facts = append(facts, "name: "+name)
	}
	if match.Age > 0 {
		facts = append(facts, fmt.Sprintf("age: %d", match.Age))
	}
	if message := strings.TrimSpace(match.Message); message != "" {
		facts = append(facts, "they wrote: “"+message+"”")
	}
	if interests := strings.TrimSpace(match.Interests); interests != "" {
		facts = append(facts, "interests: "+interests)
	}
	if len(facts) == 0 {
		return ""
	}
	return "About the match:\n- " + strings.Join(facts, "\n- ")
}

// describeOpeningLineRequest — запрос первой фразы.
func describeOpeningLineRequest(req model.OpeningLineRequest, hasProfile bool) string {
	sections := []string{describeSpice(req.Spice), describeYou(req.You)}
	if match := describeMatch(req.Match); match != "" {
		sections = append(sections, match)
	}
	if hasProfile {
		sections = append(sections, "The match's profile screenshot is attached.")
	}
	if lines := nonEmpty(req.PreviousLines); len(lines) > 0 {
		sections = append(sections, "Lines you already suggested — write something different:\n- "+strings.Join(lines, "\n- "))
	}
	sections = append(sections, "Write the opening line.")
	return strings.Join(sections, "\n\n")
}

// describeCoachRequest — новое сообщение коучу со всем, что было до него.
func describeCoachRequest(req model.CoachRequest, hasScreenshot bool) string {
	sections := []string{describeTone(req.Tone) + " " + describeSpice(req.Spice), describeYou(req.You)}

	if chat := req.Chat; chat != nil {
		about := "The chat you are talking about is with " + strings.TrimSpace(chat.Name)
		if chat.Age > 0 {
			about += fmt.Sprintf(", %d", chat.Age)
		}
		about += "."
		if verdict := strings.TrimSpace(chat.Verdict); verdict != "" {
			about += " Your read of it: " + verdict
		}
		sections = append(sections, about)
	}
	if req.Breakdown != nil {
		if breakdown, err := json.Marshal(req.Breakdown); err == nil {
			sections = append(sections, "Your breakdown of this chat:\n"+string(breakdown))
		}
	}
	if transcript := describeConversation(req.Messages); transcript != "" {
		sections = append(sections, "Your conversation with the user so far:\n"+transcript)
	}
	if suggested := suggestedMessages(req.Messages); len(suggested) > 0 {
		sections = append(sections, "Messages you already suggested — don't suggest them again:\n- "+strings.Join(suggested, "\n- "))
	}
	if hasScreenshot {
		sections = append(sections, "The user attached a new screenshot of their chat with the match.")
	}
	if text := strings.TrimSpace(req.Text); text != "" {
		sections = append(sections, "The user's new message:\n"+text)
	} else {
		sections = append(sections, "The user sent no text: give your read of the chat and the message to send next.")
	}
	return strings.Join(sections, "\n\n")
}

// describeConversation — разговор с коучем репликами «User:» и «Cue:».
func describeConversation(messages []model.CoachMessage) string {
	var lines []string
	for _, message := range messages {
		text := strings.TrimSpace(message.Text)
		if message.From == "coach" {
			if text != "" {
				lines = append(lines, "Cue: "+text)
			}
			if suggestion := message.Suggestion; suggestion != nil && strings.TrimSpace(suggestion.Text) != "" {
				lines = append(lines, "Cue suggested sending: "+strings.TrimSpace(suggestion.Text))
			}
			continue
		}
		if text == "" {
			text = "(shared a screenshot of the chat)"
		}
		lines = append(lines, "User: "+text)
	}
	return strings.Join(lines, "\n")
}

// suggestedMessages — всё, что коуч уже предлагал отправить.
func suggestedMessages(messages []model.CoachMessage) []string {
	var suggested []string
	for _, message := range messages {
		if message.Suggestion != nil {
			suggested = append(suggested, message.Suggestion.Text)
		}
	}
	return nonEmpty(suggested)
}

func nonEmpty(values []string) []string {
	var result []string
	for _, value := range values {
		if value = strings.TrimSpace(value); value != "" {
			result = append(result, value)
		}
	}
	return result
}

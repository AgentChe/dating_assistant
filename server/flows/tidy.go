package flows

import (
	"strings"
	"unicode"
	"unicode/utf8"
)

// Страховка от редкого сбоя модели: в короткое поле иногда попадают её рассуждения
// («Sam customer profile name is Sam, age 27, … Let's strictly follow schema guidelines»).
// Схема длину строк не ограничивает, поэтому порядок наводит сервер.

// tidyName — имя мэтча: обычное имя как есть; если пришла фраза — первое слово, когда оно похоже на имя,
// иначе пусто.
func tidyName(name string) string {
	name = strings.TrimSpace(name)
	words := strings.Fields(name)
	if utf8.RuneCountInString(name) <= 30 && len(words) <= 3 && !strings.ContainsAny(name, "\n:;") {
		return name
	}
	if len(words) == 0 {
		return ""
	}
	// Обычно модель пишет имя и дальше рассуждает: первое слово и есть имя. Но только если оно похоже на имя —
	// с заглавной буквы, из букв и не служебное («The match's name is…»).
	first := strings.TrimRight(words[0], ".,:;!?")
	runes := []rune(first)
	if len(runes) == 0 || len(runes) > 20 || !unicode.IsUpper(runes[0]) || notNames[strings.ToLower(first)] {
		return ""
	}
	for _, r := range runes {
		if !unicode.IsLetter(r) && r != '-' && r != '\'' && r != '’' {
			return ""
		}
	}
	return first
}

var notNames = map[string]bool{
	"the": true, "a": true, "an": true, "this": true, "that": true, "their": true, "his": true, "her": true,
	"my": true, "your": true, "user": true, "match": true, "name": true, "profile": true, "chat": true,
}

// shortOrEmpty — необязательное поле: длиннее [limit] символов — это уже не значение, а рассуждения, и поле
// не показываем.
func shortOrEmpty(value string, limit int) string {
	value = strings.TrimSpace(value)
	if utf8.RuneCountInString(value) > limit {
		return ""
	}
	return value
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

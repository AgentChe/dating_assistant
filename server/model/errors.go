package model

import "errors"

// InputError — запрос не прошёл проверку; приложение получит 400 с этим текстом.
type InputError struct {
	Message string
}

func (e *InputError) Error() string { return e.Message }

// ErrNotAChat — на скриншоте нет переписки, которую можно разобрать; приложение получит 422.
var ErrNotAChat = errors.New("the screenshot is not a readable chat")

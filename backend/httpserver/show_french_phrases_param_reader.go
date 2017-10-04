package httpserver

import (
	"errors"
	"net/http"

	"github.com/google/uuid"
)

//go:generate counterfeiter . ShowFrenchPhrasesParamReader
type ShowFrenchPhrasesParamReader interface {
	ReadParamsFromRequest(*http.Request) (ShowFrenchPhrasesParams, error)
}

type ShowFrenchPhrasesParams struct {
	UserUUID uuid.UUID
}

func NewShowFrenchPhrasesParamReader() ShowFrenchPhrasesParamReader {
	return showFrenchPhrasesParamReader{}
}

type showFrenchPhrasesParamReader struct{}

func (paramReader showFrenchPhrasesParamReader) ReadParamsFromRequest(
	request *http.Request,
) (ShowFrenchPhrasesParams, error) {
	tokens, ok := request.Header["X-User-Token"]
	if !ok {
		return ShowFrenchPhrasesParams{}, errors.New(`{"err": "You done goofed; I'm pretty sure you didn't authenticate"}`)
	}

	userUuid, err := uuid.Parse(tokens[0])
	if err != nil {
		return ShowFrenchPhrasesParams{}, err
	}

	return ShowFrenchPhrasesParams{
		UserUUID: userUuid,
	}, nil
}

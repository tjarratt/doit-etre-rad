package httpserver

import (
	"errors"
	"net/http"

	"github.com/google/uuid"
)

//go:generate counterfeiter . ShowPhrasesParamReader
type ShowPhrasesParamReader interface {
	ReadParamsFromRequest(*http.Request) (ShowPhrasesParams, error)
}

type ShowPhrasesParams struct {
	UserUUID uuid.UUID
}

func NewShowPhrasesParamReader() ShowPhrasesParamReader {
	return showPhrasesParamReader{}
}

type showPhrasesParamReader struct{}

func (paramReader showPhrasesParamReader) ReadParamsFromRequest(
	request *http.Request,
) (ShowPhrasesParams, error) {
	tokens, ok := request.Header["X-User-Token"]
	if !ok {
		return ShowPhrasesParams{}, errors.New(`{"err": "You done goofed; I'm pretty sure you didn't authenticate"}`)
	}

	userUuid, err := uuid.Parse(tokens[0])
	if err != nil {
		return ShowPhrasesParams{}, err
	}

	return ShowPhrasesParams{
		UserUUID: userUuid,
	}, nil
}

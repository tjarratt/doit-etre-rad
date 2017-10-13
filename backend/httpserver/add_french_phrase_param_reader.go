package httpserver

import (
	"encoding/json"
	"errors"
	"io/ioutil"
	"net/http"

	"github.com/google/uuid"
)

//go:generate counterfeiter . AddFrenchPhraseParamReader
type AddFrenchPhraseParamReader interface {
	ReadParamsFromRequest(*http.Request) (AddFrenchPhraseParams, error)
}

type AddFrenchPhraseParams struct {
	Phrase   string
	UserUUID uuid.UUID
}

func NewAddFrenchPhraseParamReader() AddFrenchPhraseParamReader {
	return addFrenchPhraseParamReader{}
}

type addFrenchPhraseParamReader struct{}

func (paramReader addFrenchPhraseParamReader) ReadParamsFromRequest(
	request *http.Request,
) (AddFrenchPhraseParams, error) {
	tokens, ok := request.Header["X-User-Token"]
	if !ok {
		return AddFrenchPhraseParams{}, errors.New(`{"err": "You done goofed; I'm pretty sure you didn't authenticate"}`)
	}

	userUuid, err := uuid.Parse(tokens[0])
	if err != nil {
		return AddFrenchPhraseParams{}, err
	}

	bodyStr, err := ioutil.ReadAll(request.Body)
	if err != nil {
		return AddFrenchPhraseParams{}, err
	}

	requestObj := map[string]string{}
	err = json.Unmarshal(bodyStr, &requestObj)
	if err != nil {
		return AddFrenchPhraseParams{}, err
	}

	content, ok := requestObj["content"]
	if !ok {
		return AddFrenchPhraseParams{}, errors.New(`{"err": "Could not read phrase from request body"}`)
	}

	return AddFrenchPhraseParams{
		Phrase:   content,
		UserUUID: userUuid,
	}, nil
}

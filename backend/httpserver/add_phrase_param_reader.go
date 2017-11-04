package httpserver

import (
	"encoding/json"
	"errors"
	"io/ioutil"
	"net/http"

	"github.com/google/uuid"
)

//go:generate counterfeiter . AddPhraseParamReader
type AddPhraseParamReader interface {
	ReadParamsFromRequest(*http.Request) (AddPhraseParams, error)
}

type AddPhraseParams struct {
	Phrase   string
	UserUUID uuid.UUID
}

func NewAddPhraseParamReader() AddPhraseParamReader {
	return addPhraseParamReader{}
}

type addPhraseParamReader struct{}

func (paramReader addPhraseParamReader) ReadParamsFromRequest(
	request *http.Request,
) (AddPhraseParams, error) {
	tokens, ok := request.Header["X-User-Token"]
	if !ok {
		return AddPhraseParams{}, errors.New(`{"err": "You done goofed; I'm pretty sure you didn't authenticate"}`)
	}

	userUuid, err := uuid.Parse(tokens[0])
	if err != nil {
		return AddPhraseParams{}, err
	}

	bodyStr, err := ioutil.ReadAll(request.Body)
	if err != nil {
		return AddPhraseParams{}, err
	}

	requestObj := map[string]string{}
	err = json.Unmarshal(bodyStr, &requestObj)
	if err != nil {
		return AddPhraseParams{}, err
	}

	content, ok := requestObj["content"]
	if !ok {
		return AddPhraseParams{}, errors.New(`{"err": "Could not read phrase from request body"}`)
	}

	return AddPhraseParams{
		Phrase:   content,
		UserUUID: userUuid,
	}, nil
}

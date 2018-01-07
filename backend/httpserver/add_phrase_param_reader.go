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
	ReadParamsFromRequest(*http.Request) ([]AddPhraseParams, *uuid.UUID, error)
}

type AddPhraseParams struct {
	Phrase      string
	Translation string
	UUID        *uuid.UUID
}

func NewAddPhraseParamReader() AddPhraseParamReader {
	return addPhraseParamReader{}
}

type addPhraseParamReader struct{}

func (paramReader addPhraseParamReader) ReadParamsFromRequest(
	request *http.Request,
) ([]AddPhraseParams, *uuid.UUID, error) {
	tokens, ok := request.Header["X-User-Token"]
	if !ok {
		return []AddPhraseParams{}, nil, errors.New("you done goofed; I'm pretty sure you didn't authenticate")
	}

	userUuid, err := uuid.Parse(tokens[0])
	if err != nil {
		return []AddPhraseParams{}, nil, err
	}

	bodyStr, err := ioutil.ReadAll(request.Body)
	if err != nil {
		return []AddPhraseParams{}, nil, err
	}

	requestObj := []map[string]string{}
	err = json.Unmarshal(bodyStr, &requestObj)
	if err != nil {
		return []AddPhraseParams{}, nil, err
	}
	if len(requestObj) == 0 {
		return []AddPhraseParams{}, nil, errors.New("You must specify at least one phrase")
	}

	params := []AddPhraseParams{}
	for _, obj := range requestObj {
		content, ok := obj["content"]
		if !ok {
			return []AddPhraseParams{}, nil, errors.New("could not read phrase from request body")
		}

		var phraseUUID *uuid.UUID
		parsedUUID, err := uuid.Parse(obj["uuid"])
		if err != nil {
			phraseUUID = nil
		} else {
			phraseUUID = &parsedUUID
		}

		translation, ok := obj["translation"]
		if !ok {
			translation = ""
		}

		params = append(params, AddPhraseParams{
			UUID:        phraseUUID,
			Phrase:      content,
			Translation: translation,
		})
	}

	return params, &userUuid, nil
}

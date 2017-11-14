package httpserver

import (
	"encoding/json"
	"errors"
	"io/ioutil"
	"net/http"

	"github.com/google/uuid"
)

type UpdatePhraseParamReader interface {
	ReadParamsFromRequest(*http.Request) (updatePhraseParams, error)
}

type updatePhraseParams struct {
	Content     string
	Translation string
	UserUUID    uuid.UUID
}

func NewUpdatePhraseParamReader() UpdatePhraseParamReader {
	return updatePhraseParamReader{}
}

type updatePhraseParamReader struct{}

func (reader updatePhraseParamReader) ReadParamsFromRequest(request *http.Request) (updatePhraseParams, error) {
	tokens, ok := request.Header["X-User-Token"]
	if !ok {
		return updatePhraseParams{}, errors.New(`{"err": "You done goofed; I'm pretty sure you didn't authenticate"}`)
	}

	userUuid, err := uuid.Parse(tokens[0])
	if err != nil {
		return updatePhraseParams{}, err
	}

	bodyStr, err := ioutil.ReadAll(request.Body)
	if err != nil {
		return updatePhraseParams{}, err
	}

	requestObj := map[string]string{}
	err = json.Unmarshal(bodyStr, &requestObj)
	if err != nil {
		return updatePhraseParams{}, err
	}

	content, ok := requestObj["content"]
	if !ok {
		content = ""
	}
	translation, ok := requestObj["translation"]
	if !ok {
		translation = ""
	}

	return updatePhraseParams{
		UserUUID:    userUuid,
		Content:     content,
		Translation: translation,
	}, nil
}

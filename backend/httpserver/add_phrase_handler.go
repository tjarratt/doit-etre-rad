package httpserver

import (
	"encoding/json"
	"errors"
	"fmt"
	"net/http"

	"github.com/tjarratt/doit-etre-rad/backend/usecases"
)

type AddPhraseHandler interface {
	http.Handler
}

func NewAddPhraseHandler(
	useCase usecases.AddPhraseUseCase,
	paramReader AddPhraseParamReader,
) http.Handler {
	return addPhraseHandler{
		useCase:     useCase,
		paramReader: paramReader,
	}
}

type addPhraseHandler struct {
	useCase     usecases.AddPhraseUseCase
	paramReader AddPhraseParamReader
}

func (handler addPhraseHandler) ServeHTTP(writer http.ResponseWriter, request *http.Request) {
	params, userUuid, err := handler.paramReader.ReadParamsFromRequest(request)
	if err != nil {
		writeError(writer, err, http.StatusBadRequest)
		return
	}

	phrase, err := handler.useCase.Execute(usecases.AddPhraseRequest{
		UserUUID: *userUuid,
		Phrases:  mapPhrases(params),
	})

	if err != nil {
		writeError(writer, err, http.StatusBadRequest)
		return
	}

	responseBody, err := json.Marshal(phrase)
	if err != nil {
		writeError(writer, err, http.StatusInternalServerError)
		return
	}

	writer.Write([]byte(responseBody))
}

func mapPhrases(params []AddPhraseParams) []usecases.AddPhraseItem {
	result := []usecases.AddPhraseItem{}
	for _, p := range params {
		result = append(result, usecases.AddPhraseItem{
			Phrase:      p.Phrase,
			Translation: p.Translation,
			UUID:        p.UUID,
		})
	}

	return result
}

func writeError(writer http.ResponseWriter, err error, statusCode int) {
	writer.WriteHeader(statusCode)
	writer.Write([]byte(wrap(err).Error()))
}

func wrap(err error) error {
	return errors.New(fmt.Sprintf(`{"error": "%s"}`, err.Error()))
}

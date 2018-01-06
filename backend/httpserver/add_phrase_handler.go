package httpserver

import (
	"encoding/json"
	"net/http"
	"errors"
	"fmt"

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
	params, err := handler.paramReader.ReadParamsFromRequest(request)
	if err != nil {
		writeError(writer, err, http.StatusBadRequest)
		return
	}

	phrase, err := handler.useCase.Execute(usecases.AddPhraseRequest{
		UserUUID:    params.UserUUID,
		Phrase:      params.Phrase,
		Translation: params.Translation,
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

func writeError(writer http.ResponseWriter, err error, statusCode int) {
	writer.WriteHeader(statusCode)
	writer.Write([]byte(wrap(err).Error()))
}

func wrap(err error) error {
	return errors.New(fmt.Sprintf(`{"error": "%s"}`, err.Error()))
}

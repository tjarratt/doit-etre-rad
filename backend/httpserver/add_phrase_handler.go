package httpserver

import (
	"encoding/json"
	"net/http"

	"github.com/tjarratt/doit-etre-rad/backend/usecases"
)

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
		writer.WriteHeader(http.StatusBadRequest)
		writer.Write([]byte(err.Error()))
		return
	}

	phrase, err := handler.useCase.Execute(usecases.AddPhraseRequest{
		UserUUID:    params.UserUUID,
		Phrase:      params.Phrase,
		Translation: params.Translation,
	})

	if err != nil {
		writer.WriteHeader(http.StatusBadRequest)
		writer.Write([]byte(wrap(err).Error()))
		return
	}

	responseBody, err := json.Marshal(phrase)
	if err != nil {
		writer.WriteHeader(http.StatusInternalServerError)
		writer.Write([]byte(wrap(err).Error()))
		return
	}

	writer.Write([]byte(responseBody))
}

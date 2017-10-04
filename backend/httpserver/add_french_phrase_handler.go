package httpserver

import (
	"encoding/json"
	"net/http"

	"github.com/tjarratt/doit-etre-rad/backend/usecases"
)

func NewAddFrenchPhraseHandler(
	useCase usecases.AddFrenchPhraseUseCase,
	paramReader AddFrenchPhraseParamReader,
) http.Handler {
	return addFrenchPhraseHandler{
		useCase:     useCase,
		paramReader: paramReader,
	}
}

type addFrenchPhraseHandler struct {
	useCase     usecases.AddFrenchPhraseUseCase
	paramReader AddFrenchPhraseParamReader
}

func (handler addFrenchPhraseHandler) ServeHTTP(writer http.ResponseWriter, request *http.Request) {

	params, err := handler.paramReader.ReadParamsFromRequest(request)
	if err != nil {
		writer.WriteHeader(http.StatusBadRequest)
		writer.Write([]byte(err.Error()))
		return
	}

	phrase, err := handler.useCase.Execute(usecases.AddFrenchPhraseRequest{
		Phrase:   params.Phrase,
		UserUUID: params.UserUUID,
	})

	if err != nil {
		writer.WriteHeader(http.StatusBadRequest)
		writer.Write([]byte(err.Error()))
		return
	}

	responseBody, err := json.Marshal(phrase)
	if err != nil {
		writer.WriteHeader(http.StatusInternalServerError)
		writer.Write([]byte(err.Error()))
		return
	}

	writer.Write([]byte(responseBody))
}

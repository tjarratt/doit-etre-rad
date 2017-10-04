package httpserver

import (
	"encoding/json"
	"net/http"

	"github.com/tjarratt/doit-etre-rad/backend/usecases"
)

func NewShowFrenchPhrasesHandler(
	useCase usecases.ShowFrenchPhrasesUseCase,
	paramReader ShowFrenchPhrasesParamReader,
) http.Handler {
	return showFrenchPhrasesHandler{
		useCase:     useCase,
		paramReader: paramReader,
	}
}

type showFrenchPhrasesHandler struct {
	useCase     usecases.ShowFrenchPhrasesUseCase
	paramReader ShowFrenchPhrasesParamReader
}

func (handler showFrenchPhrasesHandler) ServeHTTP(writer http.ResponseWriter, request *http.Request) {

	params, err := handler.paramReader.ReadParamsFromRequest(request)
	if err != nil {
		writer.WriteHeader(http.StatusBadRequest)
		writer.Write([]byte(err.Error()))
		return
	}

	phrases, err := handler.useCase.Execute(usecases.ShowFrenchPhrasesRequest{
		UserUUID: params.UserUUID,
	})

	if err != nil {
		writer.WriteHeader(http.StatusBadRequest)
		writer.Write([]byte(err.Error()))
		return
	}

	responseBody, err := json.Marshal(phrases)
	if err != nil {
		writer.WriteHeader(http.StatusInternalServerError)
		writer.Write([]byte(err.Error()))
		return
	}

	writer.Write([]byte(responseBody))
}

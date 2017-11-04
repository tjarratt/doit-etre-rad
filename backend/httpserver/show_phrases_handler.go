package httpserver

import (
	"encoding/json"
	"net/http"

	"github.com/tjarratt/doit-etre-rad/backend/usecases"
)

func NewShowPhrasesHandler(
	useCase usecases.ShowPhrasesUseCase,
	paramReader ShowPhrasesParamReader,
) http.Handler {
	return showPhrasesHandler{
		useCase:     useCase,
		paramReader: paramReader,
	}
}

type showPhrasesHandler struct {
	useCase     usecases.ShowPhrasesUseCase
	paramReader ShowPhrasesParamReader
}

func (handler showPhrasesHandler) ServeHTTP(writer http.ResponseWriter, request *http.Request) {

	params, err := handler.paramReader.ReadParamsFromRequest(request)
	if err != nil {
		writer.WriteHeader(http.StatusBadRequest)
		writer.Write([]byte(err.Error()))
		return
	}

	phrases, err := handler.useCase.Execute(usecases.ShowPhrasesRequest{
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

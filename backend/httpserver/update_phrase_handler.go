package httpserver

import (
	"encoding/json"
	"net/http"

	"github.com/google/uuid"
	"github.com/gorilla/mux"
	"github.com/tjarratt/doit-etre-rad/backend/usecases"
)

func NewUpdatePhraseHandler(
	useCase usecases.UpdatePhraseUseCase,
	paramReader UpdatePhraseParamReader,
) http.Handler {
	return updatePhraseHandler{
		useCase:     useCase,
		paramReader: paramReader,
	}
}

type updatePhraseHandler struct {
	useCase     usecases.UpdatePhraseUseCase
	paramReader UpdatePhraseParamReader
}

func (handler updatePhraseHandler) ServeHTTP(writer http.ResponseWriter, request *http.Request) {
	params, err := handler.paramReader.ReadParamsFromRequest(request)
	if err != nil {
		writer.WriteHeader(http.StatusBadRequest)
		writer.Write([]byte(err.Error()))
		return
	}

	requestVars := mux.Vars(request)
	phraseUUID, err := uuid.Parse(requestVars["uuid"])
	if err != nil {
		writer.WriteHeader(http.StatusBadRequest)
		writer.Write([]byte(`{"err": "invalid phrase uuid"}`))
	}

	phrase, err := handler.useCase.Execute(usecases.UpdatePhraseRequest{
		UserUUID:    params.UserUUID,
		UUID:        phraseUUID,
		Content:     params.Content,
		Translation: params.Translation,
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

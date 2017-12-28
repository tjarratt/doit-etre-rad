package httpserver

import (
	"errors"
	json2 "encoding/json"
	"net/http"

	"github.com/tjarratt/doit-etre-rad/backend/api"
)

type AdminHandler interface {
	http.Handler
}

func NewAdminHandler(repository api.AdminRepository, password string) http.Handler {
	return &adminHandler{
		password: password,
		repository: repository,
	}
}

type adminHandler struct {
	password   string
	repository api.AdminRepository
}

func (handler *adminHandler) ServeHTTP(writer http.ResponseWriter, request *http.Request) {
	passwords, ok := request.Header["X-Password"]
	if !ok || len(passwords) == 0 || passwords[0] != handler.password {
		writeError(writer, errors.New("ah ah ah, you didn't say the magic word"), http.StatusUnauthorized)
		return
	}

	phrases, err := handler.repository.PhraseCountByUserUUID()
	if err != nil {
		writeError(writer, err, http.StatusInternalServerError)
		return
	}

	responseBody, err := json2.Marshal(phrases)
	if err != nil {
		writeError(writer, err, http.StatusInternalServerError)
		return
	}

	writer.Write([]byte(responseBody))
}

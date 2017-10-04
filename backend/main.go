package main

import (
	"fmt"
	"net/http"
	"os"

	"github.com/gorilla/mux"
	"github.com/tjarratt/doit-etre-rad/backend/api"
	"github.com/tjarratt/doit-etre-rad/backend/db"
	"github.com/tjarratt/doit-etre-rad/backend/httpserver"
	"github.com/tjarratt/doit-etre-rad/backend/usecases"

	cfenv "github.com/cloudfoundry-community/go-cfenv"
	_ "github.com/go-sql-driver/mysql"
)

func main() {
	router := mux.NewRouter()

	app, err := cfenv.Current()
	if err != nil {
		panic(err.Error())
	}

	db := db.OpenConnectionOrPanic(app)
	repository := api.NewFrenchPhrasesRepository(db)
	showHandler := httpserver.NewShowFrenchPhrasesHandler(
		usecases.NewShowFrenchPhrasesUseCase(
			repository,
		),
		httpserver.NewShowFrenchPhrasesParamReader(),
	)
	router.Handle("/phrases/french", showHandler).Methods("GET")

	writeHandler := httpserver.NewAddFrenchPhraseHandler(
		usecases.NewAddFrenchPhraseUseCase(repository),
		httpserver.NewAddFrenchPhraseParamReader(),
	)
	router.Handle("/phrases/french", writeHandler).Methods("POST")

	port := app.Port
	fmt.Fprintln(os.Stdout, "listening on port ", port)

	err = http.ListenAndServe(fmt.Sprintf(":%d", port), router)
	if err != nil {
		panic(err.Error())
	}
}

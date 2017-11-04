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
	frenchPhraseRepository := api.NewPhrasesRepository(api.FRENCH_TO_ENGLISH, db)
	englishPhraseRepository := api.NewPhrasesRepository(api.ENGLISH_TO_FRENCH, db)

	showFrenchHandler := httpserver.NewShowPhrasesHandler(
		usecases.NewShowPhrasesUseCase(frenchPhraseRepository),
		httpserver.NewShowPhrasesParamReader(),
	)
	router.Handle("/api/phrases/french", showFrenchHandler).Methods("GET")

	showEnglishHandler := httpserver.NewShowPhrasesHandler(
		usecases.NewShowPhrasesUseCase(englishPhraseRepository),
		httpserver.NewShowPhrasesParamReader(),
	)
	router.Handle("/api/phrases/english", showEnglishHandler).Methods("GET")

	addFrenchHandler := httpserver.NewAddPhraseHandler(
		usecases.NewAddPhraseUseCase(frenchPhraseRepository),
		httpserver.NewAddPhraseParamReader(),
	)
	router.Handle("/api/phrases/french", addFrenchHandler).Methods("POST")

	addEnglishHandler := httpserver.NewAddPhraseHandler(
		usecases.NewAddPhraseUseCase(englishPhraseRepository),
		httpserver.NewAddPhraseParamReader(),
	)
	router.Handle("/api/phrases/english", addEnglishHandler).Methods("POST")

	router.NotFoundHandler = http.HandlerFunc(NotFoundHandler)

	port := app.Port
	fmt.Fprintln(os.Stdout, "listening on port ", port)

	err = http.ListenAndServe(fmt.Sprintf(":%d", port), router)
	if err != nil {
		panic(err.Error())
	}
}

func NotFoundHandler(rw http.ResponseWriter, req *http.Request) {
	path := req.RequestURI
	rw.WriteHeader(http.StatusBadRequest)
	rw.Write([]byte(fmt.Sprintf("You done goofed son : '%s'", path)))
}

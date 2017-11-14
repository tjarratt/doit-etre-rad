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

	showFrenchHandler := ShowPhrasesHandler(frenchPhraseRepository)
	router.Handle("/api/phrases/french", showFrenchHandler).Methods("GET")

	showEnglishHandler := ShowPhrasesHandler(englishPhraseRepository)
	router.Handle("/api/phrases/english", showEnglishHandler).Methods("GET")

	addFrenchHandler := AddPhraseHandler(frenchPhraseRepository)
	router.Handle("/api/phrases/french", addFrenchHandler).Methods("POST")

	addEnglishHandler := AddPhraseHandler(englishPhraseRepository)
	router.Handle("/api/phrases/english", addEnglishHandler).Methods("POST")

	frenchUpdateHandler := UpdatePhraseHandler(frenchPhraseRepository)
	router.Handle("/api/phrases/french/{uuid}", frenchUpdateHandler).Methods("PUT")

	englishUpdateHandler := UpdatePhraseHandler(englishPhraseRepository)
	router.Handle("/api/phrases/english/{uuid}", englishUpdateHandler).Methods("PUT")

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

func UpdatePhraseHandler(repo api.PhrasesRepository) http.Handler {
	return httpserver.NewUpdatePhraseHandler(
		usecases.NewUpdatePhraseUseCase(repo),
		httpserver.NewUpdatePhraseParamReader(),
	)
}

func AddPhraseHandler(repo api.PhrasesRepository) http.Handler {
	return httpserver.NewAddPhraseHandler(
		usecases.NewAddPhraseUseCase(repo),
		httpserver.NewAddPhraseParamReader(),
	)
}

func ShowPhrasesHandler(repo api.PhrasesRepository) http.Handler {
	return httpserver.NewShowPhrasesHandler(
		usecases.NewShowPhrasesUseCase(repo),
		httpserver.NewShowPhrasesParamReader(),
	)
}

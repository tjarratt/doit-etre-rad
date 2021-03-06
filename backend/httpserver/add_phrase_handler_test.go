package httpserver_test

import (
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"

	"github.com/google/uuid"
	"github.com/tjarratt/doit-etre-rad/backend/httpserver/httpserverfakes"
	"github.com/tjarratt/doit-etre-rad/backend/usecases"
	"github.com/tjarratt/doit-etre-rad/backend/usecases/usecasesfakes"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/tjarratt/doit-etre-rad/backend/httpserver"
)

var _ = Describe("AddPhraseHandler", func() {
	var subject AddPhraseHandler

	var useCase *usecasesfakes.FakeAddPhraseUseCase
	var paramReader *httpserverfakes.FakeAddPhraseParamReader
	var writer *httptest.ResponseRecorder

	BeforeEach(func() {
		useCase = new(usecasesfakes.FakeAddPhraseUseCase)
		paramReader = new(httpserverfakes.FakeAddPhraseParamReader)
		writer = httptest.NewRecorder()
	})

	BeforeEach(func() {
		subject = NewAddPhraseHandler(useCase, paramReader)
	})

	JustBeforeEach(func() {
		request, err := http.NewRequest("GET", "http://example.com/api", strings.NewReader("shrugie"))
		Expect(err).NotTo(HaveOccurred())

		subject.ServeHTTP(writer, request)
	})

	Describe("a successful request", func() {
		phraseUUID := uuid.Must(uuid.Parse("2dff2424-c888-4785-a91d-6fcb006dabe5"))

		BeforeEach(func() {
			paramReader.ReadParamsFromRequestReturns([]AddPhraseParams{{
				Phrase:      "the-content",
				Translation: "the-translation",
				UUID:        &phraseUUID,
			}}, &userUUID, nil)
			phraseResponse := []usecases.PhraseResponse{{
				Uuid:        "the-uuid",
				Content:     "the-content",
				Translation: "the-translation",
			}}
			useCase.ExecuteReturns(phraseResponse, nil)
		})

		It("returns JSON describing the resource created", func() {
			expectedBody := `[{"uuid":"the-uuid","content":"the-content","translation":"the-translation"}]`
			Expect(writer.Body.String()).To(Equal(expectedBody))
		})

		It("provides the phrases to the use case", func() {
			Expect(useCase.ExecuteCallCount()).To(Equal(1))

			request := useCase.ExecuteArgsForCall(0)
			Expect(request.UserUUID).To(Equal(userUUID))
			Expect(request.Phrases).To(Equal([]usecases.AddPhraseItem{{
				Phrase:      "the-content",
				Translation: "the-translation",
				UUID:        &phraseUUID,
			}}))
		})
	})

	Describe("when the params cannot be read", func() {
		BeforeEach(func() {
			paramReader.ReadParamsFromRequestReturns([]AddPhraseParams{}, nil, errors.New("too many splines to reticulate"))
		})

		It("returns an error when the params cannot be read", func() {
			expectedError := `{"error": "too many splines to reticulate"}`
			Expect(writer.Body.String()).To(Equal(expectedError))
		})
	})

	Describe("when the usecase returns an error", func() {
		BeforeEach(func() {
			paramReader.ReadParamsFromRequestReturns([]AddPhraseParams{}, &userUUID, nil)
			useCase.ExecuteReturns([]usecases.PhraseResponse{}, errors.New("retro encabulator waneshaft requires new lunar ambifacient"))
		})

		It("returns an error when the use case returns an error", func() {
			expectedError := `{"error": "retro encabulator waneshaft requires new lunar ambifacient"}`
			Expect(writer.Body.String()).To(Equal(expectedError))
		})
	})
})

var userUUID = uuid.Must(uuid.Parse("e2580a5b-cabb-4387-bcea-30e9401a2aa4"))

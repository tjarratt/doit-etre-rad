package httpserver_test

import (
	"errors"
	"net/http/httptest"
	"net/http"
	"strings"

	"github.com/tjarratt/doit-etre-rad/backend/api/apifakes"
	"github.com/tjarratt/doit-etre-rad/backend/api"

	. "github.com/tjarratt/doit-etre-rad/backend/httpserver"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("AdminHandler", func() {
	var subject AdminHandler

	var adminRepository *apifakes.FakeAdminRepository

	var request *http.Request
	var writer *httptest.ResponseRecorder

	BeforeEach(func() {
		writer = httptest.NewRecorder()
		adminRepository = new(apifakes.FakeAdminRepository)
		subject = NewAdminHandler(adminRepository, "really-thoughtful-password")
	})

	BeforeEach(func() {
		var err error
		request, err = http.NewRequest("GET", "http://example.com/api/admin", strings.NewReader(""))
		Expect(err).NotTo(HaveOccurred())
	})

	JustBeforeEach(func() {
		subject.ServeHTTP(writer, request)
	})

	Describe("a successful request", func() {
		BeforeEach(func() {
			phrases := []api.PhraseCount{{"the-uuid", 666}}
			adminRepository.PhraseCountByUserUUIDReturns(phrases, nil)

			request.Header.Add("X-Password", "really-thoughtful-password")
		})

		It("returns JSON describing the resource created", func() {
			expectedBody := `[{"userUuid":"the-uuid","phraseCount":666}]`
			Expect(writer.Body.String()).To(Equal(expectedBody))
		})
	})

	Describe("when the user fails to provide the correct password", func() {
		BeforeEach(func() {
			phrases := []api.PhraseCount{{"the-uuid", 666}}
			adminRepository.PhraseCountByUserUUIDReturns(phrases, nil)

			request.Header.Add("X-Password", "1337H4X0RZ")
		})

		It("returns JSON describing the resource created", func() {
			expectedBody := `{"error": "ah ah ah, you didn't say the magic word"}`
			Expect(writer.Body.String()).To(Equal(expectedBody))
		})
	})

	Describe("when the repository returns an error", func() {
		BeforeEach(func() {
			adminRepository.PhraseCountByUserUUIDReturns([]api.PhraseCount{}, errors.New("something done goofed"))
			request.Header.Add("X-Password", "really-thoughtful-password")
		})

		It("returns JSON describing the resource created", func() {
			expectedBody := `{"error": "something done goofed"}`
			Expect(writer.Body.String()).To(Equal(expectedBody))
		})
	})
})

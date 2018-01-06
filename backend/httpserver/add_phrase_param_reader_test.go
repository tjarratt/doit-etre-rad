package httpserver_test

import (
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/tjarratt/doit-etre-rad/backend/httpserver"

	"github.com/google/uuid"
	"io"
	"net/http"
	"strings"
)

var _ = Describe("AddPhraseParamReader", func() {
	var subject AddPhraseParamReader
	var result AddPhraseParams
	var resultErr error

	var request *http.Request
	var requestBody io.Reader

	JustBeforeEach(func() {
		var err error
		request, err = http.NewRequest("GET", "http://example.com/api", requestBody)
		Expect(err).NotTo(HaveOccurred())
	})

	subjectAction := func() {
		subject = NewAddPhraseParamReader()
		result, resultErr = subject.ReadParamsFromRequest(request)
	}

	Describe("when the user auth header is provided", func() {
		var userUuid = "e2580a5b-cabb-4387-bcea-30e9401a2aa4"
		var expectedUUID = uuid.Must(uuid.Parse("e2580a5b-cabb-4387-bcea-30e9401a2aa4"))

		BeforeEach(func() {
			requestBody = strings.NewReader(`{"content": "the-phrase", "translation": "the-translation"}`)
		})

		JustBeforeEach(func() {
			request.Header.Set("X-User-Token", userUuid)
			subjectAction()
		})

		It("returns an object wrapping the provided parameters", func() {
			Expect(resultErr).NotTo(HaveOccurred())

			Expect(result.Phrase).To(Equal("the-phrase"))
			Expect(result.Translation).To(Equal("the-translation"))
			Expect(result.UserUUID).To(Equal(expectedUUID))
		})

		Context("when a translation is not provided", func() {
			BeforeEach(func() {
				requestBody = strings.NewReader(`{"content": "the-phrase"}`)
			})

			It("defaults the translation to an empty string when it is not provided", func() {
				Expect(resultErr).NotTo(HaveOccurred())
				Expect(result.Translation).To(BeEmpty())
			})
		})

		Context("when no phrase is specified", func() {
			BeforeEach(func() {
				requestBody = strings.NewReader(`{}`)
			})

			It("returns an error", func() {
				Expect(resultErr).To(HaveOccurred())
			})
		})

		Context("when the request body is not valid JSON", func() {
			BeforeEach(func() {
				requestBody = strings.NewReader("you really done goofed it now")
			})

			It("returns an error", func() {
				Expect(resultErr).To(HaveOccurred())
			})
		})
	})

	Describe("when the user auth header is not a uuid", func() {
		BeforeEach(func() {
			requestBody = strings.NewReader(`{"content": "the-phrase", "translation": "the-translation"}`)
		})

		JustBeforeEach(func() {
			request.Header.Set("X-User-Token", "you crazy for this one, Rick !")
			subjectAction()
		})

		It("returns an error", func() {
			Expect(resultErr).To(HaveOccurred())
		})
	})

	Describe("when the user auth header is missing entirely", func() {
		BeforeEach(func() {
			requestBody = strings.NewReader(`{"content": "the-phrase", "translation": "the-translation"}`)
		})

		JustBeforeEach(func() {
			subjectAction()
		})

		It("returns an error", func() {
			Expect(resultErr).To(HaveOccurred())
		})
	})
})

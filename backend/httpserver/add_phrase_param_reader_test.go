package httpserver_test

import (
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/tjarratt/doit-etre-rad/backend/httpserver"

	"io"
	"net/http"
	"strings"

	"github.com/google/uuid"
)

var _ = Describe("AddPhraseParamReader", func() {
	var (
		subject    AddPhraseParamReader
		result     []AddPhraseParams
		resultUUID *uuid.UUID
		resultErr  error
	)

	var request *http.Request
	var requestBody io.Reader

	JustBeforeEach(func() {
		var err error
		request, err = http.NewRequest("GET", "http://example.com/api", requestBody)
		Expect(err).NotTo(HaveOccurred())
	})

	subjectAction := func() {
		subject = NewAddPhraseParamReader()
		result, resultUUID, resultErr = subject.ReadParamsFromRequest(request)
	}

	Describe("when the user auth header is provided", func() {
		var userUuid = "e2580a5b-cabb-4387-bcea-30e9401a2aa4"
		var expectedUUID = uuid.Must(uuid.Parse("e2580a5b-cabb-4387-bcea-30e9401a2aa4"))

		BeforeEach(func() {
			requestBody = strings.NewReader(`[{"content": "the-phrase", "translation": "the-translation"}, {"content": "old-phrase", "translation": "i18n", "uuid": "256499fb-770c-4805-bd0e-16e4f37a561c"}]`)
		})

		JustBeforeEach(func() {
			request.Header.Set("X-User-Token", userUuid)
			subjectAction()
		})

		It("returns an object wrapping the provided parameters", func() {
			Expect(resultErr).NotTo(HaveOccurred())

			Expect(result).To(HaveLen(2))
			Expect(*resultUUID).To(Equal(expectedUUID))

			Expect(result[0].Phrase).To(Equal("the-phrase"))
			Expect(result[0].Translation).To(Equal("the-translation"))
			Expect(result[0].UUID).To(BeNil())

			Expect(result[1].Phrase).To(Equal("old-phrase"))
			Expect(result[1].Translation).To(Equal("i18n"))
			Expect(*result[1].UUID).To(Equal(uuid.Must(uuid.Parse("256499fb-770c-4805-bd0e-16e4f37a561c"))))
		})

		Context("when a translation is not provided", func() {
			BeforeEach(func() {
				requestBody = strings.NewReader(`[{"content": "the-phrase"}]`)
			})

			It("defaults the translation to an empty string when it is not provided", func() {
				Expect(resultErr).NotTo(HaveOccurred())
				Expect(result).To(HaveLen(1))
				Expect(result[0].Phrase).To(Equal("the-phrase"))
				Expect(result[0].Translation).To(BeEmpty())
				Expect(*resultUUID).To(Equal(expectedUUID))
			})
		})

		Context("when no phrase is specified", func() {
			BeforeEach(func() {
				requestBody = strings.NewReader(`[{"translation": "whoopsie"}]`)
			})

			It("returns an error", func() {
				Expect(resultErr).To(HaveOccurred())
			})
		})

		Context("when an empty list is provided", func() {
			BeforeEach(func() {
				requestBody = strings.NewReader(`[]`)
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
			requestBody = strings.NewReader(`[{"content": "the-phrase", "translation": "the-translation"}]`)
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
			requestBody = strings.NewReader(`[{"content": "the-phrase", "translation": "the-translation"}]`)
		})

		JustBeforeEach(func() {
			subjectAction()
		})

		It("returns an error", func() {
			Expect(resultErr).To(HaveOccurred())
		})
	})
})

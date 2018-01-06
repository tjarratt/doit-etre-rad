package usecases_test

import (
	"errors"

	"github.com/google/uuid"
	"github.com/tjarratt/doit-etre-rad/backend/api"
	"github.com/tjarratt/doit-etre-rad/backend/api/apifakes"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/tjarratt/doit-etre-rad/backend/usecases"
)

var _ = Describe("AddPhraseUseCase", func() {
	var subject AddPhraseUseCase
	var fakeRepo *apifakes.FakePhrasesRepository

	BeforeEach(func() {
		fakeRepo = new(apifakes.FakePhrasesRepository)
		subject = NewAddPhraseUseCase(fakeRepo)
	})

	var response []PhraseResponse
	var err error

	JustBeforeEach(func() {
		request := AddPhraseRequest{
			UserUUID: userUUID,
			Phrases: []AddPhraseItem{{
				Phrase:      "I've got a lovely bunch of coconuts",
				Translation: "whoops",
			}, {
				Phrase:      "There they are all standing in a row",
				Translation: "oh my",
				UUID:        &phraseUUID,
			}},
		}
		response, err = subject.Execute(request)
	})

	Context("when the repository agrees to save things", func() {
		BeforeEach(func() {
			fakeRepo.AddPhraseForUserWithUUIDStub = addStub
			fakeRepo.UpdatePhraseForUserWithUUIDStub = updateStub
		})

		It("saves new phrases", func() {
			Expect(fakeRepo.AddPhraseForUserWithUUIDCallCount()).To(Equal(1))
		})

		It("updates existing phrases", func() {
			Expect(fakeRepo.UpdatePhraseForUserWithUUIDCallCount()).To(Equal(1))
		})

		It("packages up all the saved values into a single response", func() {
			Expect(response).To(HaveLen(2))
			Expect(response[0]).To(Equal(PhraseResponse{
				Uuid:        newPhraseUUID.String(),
				Content:     "I've got a lovely bunch of coconuts",
				Translation: "whoops",
			}))
			Expect(response[1]).To(Equal(PhraseResponse{
				Uuid:        phraseUUID.String(),
				Content:     "There they are all standing in a row",
				Translation: "oh my",
			}))
		})

		It("does not return an error", func() {
			Expect(err).ToNot(HaveOccurred())
		})
	})

	Context("when the repository returns an error saving a phrase", func() {
		BeforeEach(func() {
			fakeRepo.AddPhraseForUserWithUUIDStub = addStubReturnsErr
			fakeRepo.UpdatePhraseForUserWithUUIDStub = updateStub
		})

		It("returns an error", func() {
			Expect(err).To(HaveOccurred())
		})
	})

	Context("when the repository returns an error updating a phrase", func() {
		BeforeEach(func() {
			fakeRepo.AddPhraseForUserWithUUIDStub = addStub
			fakeRepo.UpdatePhraseForUserWithUUIDStub = updateStubReturnsErr
		})

		It("returns an error", func() {
			Expect(err).To(HaveOccurred())
		})
	})
})

var userUUID = uuid.Must(uuid.Parse("f2f282d9-f738-463c-ab2d-27fcb5645bca"))
var phraseUUID = uuid.Must(uuid.Parse("f56b84af-7b95-40ff-b360-888169fb7f12"))
var newPhraseUUID = uuid.Must(uuid.Parse("67d6547d-99ac-4053-8713-e63410af9dc1"))

func addStub(content, translation string, uuid uuid.UUID) (api.Phrase, error) {
	return api.Phrase{
		Uuid:        newPhraseUUID.String(),
		Content:     content,
		Translation: translation,
	}, nil
}

func addStubReturnsErr(_, _ string, _ uuid.UUID) (api.Phrase, error) {
	return api.Phrase{}, errors.New("RUH ROH")
}

func updateStub(content, translation string, phraseUuid, userUuid uuid.UUID) (api.Phrase, error) {
	return api.Phrase{
		Uuid:        phraseUuid.String(),
		Content:     content,
		Translation: translation,
	}, nil
}

func updateStubReturnsErr(_, _ string, _, _ uuid.UUID) (api.Phrase, error) {
	return api.Phrase{}, errors.New("RUH ROH")
}

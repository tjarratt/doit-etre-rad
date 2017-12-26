package usecases

import (
	"github.com/google/uuid"
	"github.com/tjarratt/doit-etre-rad/backend/api"
)

type PhraseResponse struct {
	Uuid        string `json:"uuid"`
	Content     string `json:"content"`
	Translation string `json:"translation"`
}

//go:generate counterfeiter . AddPhraseUseCase
type AddPhraseUseCase interface {
	Execute(AddPhraseRequest) (PhraseResponse, error)
}

func NewAddPhraseUseCase(
	repository api.PhrasesRepository,
) AddPhraseUseCase {
	return addPhraseUseCase{
		repository: repository,
	}
}

type addPhraseUseCase struct {
	repository api.PhrasesRepository
}

func (usecase addPhraseUseCase) Execute(request AddPhraseRequest) (PhraseResponse, error) {
	phrase, err := usecase.repository.AddPhraseForUserWithUUID(request.Phrase, request.Translation, request.UserUUID)
	return PhraseResponse(phrase), err
}

type AddPhraseRequest struct {
	Phrase      string
	Translation string
	UserUUID    uuid.UUID
}

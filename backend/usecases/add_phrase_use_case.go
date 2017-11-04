package usecases

import (
	"github.com/google/uuid"
	"github.com/tjarratt/doit-etre-rad/backend/api"
)

type PhraseResponse struct {
	Content string `json:"content"`
	Uuid    string `json:"uuid"`
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
	phrase, err := usecase.repository.AddPhraseForUserWithUUID(request.Phrase, request.UserUUID)
	return PhraseResponse(phrase), err
}

type AddPhraseRequest struct {
	Phrase   string
	UserUUID uuid.UUID
}

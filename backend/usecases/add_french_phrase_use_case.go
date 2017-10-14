package usecases

import (
	"github.com/google/uuid"
	"github.com/tjarratt/doit-etre-rad/backend/api"
)

type PhraseResponse struct {
	Content string `json:"content"`
	Uuid    string `json:"uuid"`
}

//go:generate counterfeiter . AddFrenchPhraseUseCase
type AddFrenchPhraseUseCase interface {
	Execute(AddFrenchPhraseRequest) (PhraseResponse, error)
}

func NewAddFrenchPhraseUseCase(
	repository api.FrenchPhrasesRepository,
) AddFrenchPhraseUseCase {
	return addFrenchPhraseUseCase{
		repository: repository,
	}
}

type addFrenchPhraseUseCase struct {
	repository api.FrenchPhrasesRepository
}

func (usecase addFrenchPhraseUseCase) Execute(request AddFrenchPhraseRequest) (PhraseResponse, error) {
	phrase, err := usecase.repository.AddPhraseForUserWithUUID(request.Phrase, request.UserUUID)
	return PhraseResponse(phrase), err
}

type AddFrenchPhraseRequest struct {
	Phrase   string
	UserUUID uuid.UUID
}

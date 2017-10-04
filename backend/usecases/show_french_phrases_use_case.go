package usecases

import (
	"github.com/google/uuid"
	"github.com/tjarratt/doit-etre-rad/backend/api"
)

type PhrasesResponse []PhraseResponse

//go:generate counterfeiter . ShowFrenchPhrasesUseCase
type ShowFrenchPhrasesUseCase interface {
	Execute(ShowFrenchPhrasesRequest) (PhrasesResponse, error)
}

func NewShowFrenchPhrasesUseCase(
	repository api.FrenchPhrasesRepository,
) ShowFrenchPhrasesUseCase {
	return showFrenchPhrasesUseCase{
		repository: repository,
	}
}

type showFrenchPhrasesUseCase struct {
	repository api.FrenchPhrasesRepository
}

func (usecase showFrenchPhrasesUseCase) Execute(request ShowFrenchPhrasesRequest) (PhrasesResponse, error) {
	phrases, err := usecase.repository.PhrasesForUserWithUUID(request.UserUUID)
	if err != nil {
		return []PhraseResponse{}, err
	}

	response := []PhraseResponse{}
	for _, phrase := range phrases {
		response = append(response, PhraseResponse{Content: phrase.Content, Uuid: phrase.Uuid})
	}

	return response, nil
}

type ShowFrenchPhrasesRequest struct {
	UserUUID uuid.UUID
}

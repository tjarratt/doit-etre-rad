package usecases

import (
	"github.com/google/uuid"
	"github.com/tjarratt/doit-etre-rad/backend/api"
)

type PhrasesResponse []PhraseResponse

//go:generate counterfeiter . ShowPhrasesUseCase
type ShowPhrasesUseCase interface {
	Execute(ShowPhrasesRequest) (PhrasesResponse, error)
}

func NewShowPhrasesUseCase(
	repository api.PhrasesRepository,
) ShowPhrasesUseCase {
	return showPhrasesUseCase{
		repository: repository,
	}
}

type showPhrasesUseCase struct {
	repository api.PhrasesRepository
}

func (usecase showPhrasesUseCase) Execute(request ShowPhrasesRequest) (PhrasesResponse, error) {
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

type ShowPhrasesRequest struct {
	UserUUID uuid.UUID
}

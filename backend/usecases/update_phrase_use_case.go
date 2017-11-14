package usecases

import (
	"github.com/google/uuid"
	"github.com/tjarratt/doit-etre-rad/backend/api"
)

type UpdatePhraseUseCase interface {
	Execute(UpdatePhraseRequest) (PhraseResponse, error)
}

func NewUpdatePhraseUseCase(
	repository api.PhrasesRepository,
) UpdatePhraseUseCase {
	return updatePhraseUseCase{
		repository: repository,
	}
}

type updatePhraseUseCase struct {
	repository api.PhrasesRepository
}

func (usecase updatePhraseUseCase) Execute(request UpdatePhraseRequest) (PhraseResponse, error) {
	phrase, err := usecase.repository.UpdatePhraseForUserWithUUID(
		request.Content,
		request.Translation,
		request.UUID,
		request.UserUUID,
	)
	return PhraseResponse(phrase), err
}

type UpdatePhraseRequest struct {
	Content     string
	Translation string
	UUID        uuid.UUID
	UserUUID    uuid.UUID
}

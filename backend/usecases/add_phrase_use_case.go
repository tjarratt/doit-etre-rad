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
	Execute(AddPhraseRequest) ([]PhraseResponse, error)
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

func (usecase addPhraseUseCase) Execute(request AddPhraseRequest) ([]PhraseResponse, error) {
	response := []PhraseResponse{}
	for _, phrase := range request.Phrases {
		var p api.Phrase
		var err error
		if phrase.UUID != nil {
			p, err = usecase.repository.UpdatePhraseForUserWithUUID(
				phrase.Phrase,
				phrase.Translation,
				*phrase.UUID,
				request.UserUUID,
			)
		} else {
			p, err = usecase.repository.AddPhraseForUserWithUUID(
				phrase.Phrase,
				phrase.Translation,
				request.UserUUID,
			)
		}

		if err != nil {
			return []PhraseResponse{}, err
		}

		response = append(response, PhraseResponse(p))
	}

	return response, nil

}

type AddPhraseRequest struct {
	UserUUID uuid.UUID
	Phrases  []AddPhraseItem
}

type AddPhraseItem struct {
	Phrase      string
	Translation string
	UUID        *uuid.UUID
}

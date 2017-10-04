package api

import (
	"database/sql"

	"github.com/google/uuid"
)

type Phrase struct {
	Content string
	Uuid    string
}

var FRENCH_TO_ENGLISH_TYPE = "FRENCH_TO_ENGLISH"

type FrenchPhrasesRepository interface {
	PhrasesForUserWithUUID(uuid.UUID) ([]Phrase, error)
	AddPhraseForUserWithUUID(string, uuid.UUID) (Phrase, error)
}

func NewFrenchPhrasesRepository(db *sql.DB) FrenchPhrasesRepository {
	return &frenchPhrasesRepo{db: db}
}

type frenchPhrasesRepo struct {
	db *sql.DB
}

func (repo *frenchPhrasesRepo) PhrasesForUserWithUUID(userUuid uuid.UUID) ([]Phrase, error) {
	rows, err := repo.db.Query(
		"SELECT uuid, phrase FROM phrases WHERE user_uuid = ? AND phrase_type = ?",
		userUuid.String(),
		FRENCH_TO_ENGLISH_TYPE,
	)
	if err != nil {
		return nil, err
	}

	defer rows.Close()

	results := []Phrase{}
	for rows.Next() {
		phrase := Phrase{}
		if err := rows.Scan(&phrase.Uuid, &phrase.Content); err != nil {
			return nil, err
		}
		results = append(results, phrase)
	}

	return results, nil
}

func (repo *frenchPhrasesRepo) AddPhraseForUserWithUUID(content string, userUuid uuid.UUID) (Phrase, error) {
	newUuid, err := uuid.NewRandom()
	if err != nil {
		return Phrase{}, err
	}
	_, err = repo.db.Exec(
		"INSERT INTO phrases (uuid, phrase, user_uuid, phrase_type) VALUES (?, ?, ?, ?)",
		newUuid.String(),
		content,
		userUuid,
		FRENCH_TO_ENGLISH_TYPE,
	)
	if err != nil {
		return Phrase{}, err
	}

	return Phrase{
		Uuid:    newUuid.String(),
		Content: content,
	}, nil
}

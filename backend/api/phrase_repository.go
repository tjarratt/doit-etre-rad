package api

import (
	"database/sql"

	"github.com/google/uuid"
)

type Phrase struct {
	Uuid        string
	Content     string
	Translation string
}

type PhraseType string

const FRENCH_TO_ENGLISH PhraseType = "FRENCH_TO_ENGLISH"
const ENGLISH_TO_FRENCH PhraseType = "ENGLISH_TO_FRENCH"

type PhrasesRepository interface {
	PhrasesForUserWithUUID(uuid.UUID) ([]Phrase, error)
	AddPhraseForUserWithUUID(string, string, uuid.UUID) (Phrase, error)
	UpdatePhraseForUserWithUUID(string, string, uuid.UUID, uuid.UUID) (Phrase, error)
}

func NewPhrasesRepository(phraseType PhraseType, db *sql.DB) PhrasesRepository {
	return &phrasesRepo{db: db, phraseType: phraseType}
}

type phrasesRepo struct {
	db         *sql.DB
	phraseType PhraseType
}

func (repo *phrasesRepo) PhrasesForUserWithUUID(userUuid uuid.UUID) ([]Phrase, error) {
	rows, err := repo.db.Query(
		"SELECT uuid, phrase, translation FROM phrases WHERE user_uuid = ? AND phrase_type = ?",
		userUuid.String(),
		string(repo.phraseType),
	)
	if err != nil {
		return nil, err
	}

	defer rows.Close()

	results := []Phrase{}
	for rows.Next() {
		phrase := Phrase{}
		if err := rows.Scan(
			&phrase.Uuid,
			&phrase.Content,
			&phrase.Translation,
		); err != nil {
			return nil, err
		}
		results = append(results, phrase)
	}

	return results, nil
}

func (repo *phrasesRepo) AddPhraseForUserWithUUID(content, translation string, userUuid uuid.UUID) (Phrase, error) {
	newUuid, err := uuid.NewRandom()
	if err != nil {
		return Phrase{}, err
	}
	_, err = repo.db.Exec(
		"INSERT INTO phrases (uuid, phrase, translation, user_uuid, phrase_type) VALUES (?, ?, ?, ?, ?)",
		newUuid.String(),
		content,
		translation,
		userUuid,
		string(repo.phraseType),
	)
	if err != nil {
		return Phrase{}, err
	}

	return Phrase{
		Uuid:    newUuid.String(),
		Content: content,
	}, nil
}

func (repo *phrasesRepo) UpdatePhraseForUserWithUUID(content string, translation string, phraseUuid uuid.UUID, userUuid uuid.UUID) (Phrase, error) {
	_, err := repo.db.Exec(
		"UPDATE phrases SET phrase = ?, translation = ? WHERE uuid = ? AND user_uuid = ? AND phrase_type = ?",
		content,
		translation,
		phraseUuid.String(),
		userUuid.String(),
		string(repo.phraseType),
	)
	if err != nil {
		return Phrase{}, err
	}

	return Phrase{
		Uuid:        phraseUuid.String(),
		Content:     content,
		Translation: translation,
	}, nil
}

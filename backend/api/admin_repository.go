package api

import (
	"database/sql"
)

type PhraseCount struct {
	UserUUID string `json:"userUuid"`
	PhraseCount uint `json:"phraseCount"`
}

//go:generate counterfeiter . AdminRepository
type AdminRepository interface {
	PhraseCountByUserUUID() ([]PhraseCount, error)
}

func NewAdminRepository(db *sql.DB) AdminRepository {
	return &adminRepo{db: db}
}

type adminRepo struct {
	db         *sql.DB
}

func (repo *adminRepo) PhraseCountByUserUUID() ([]PhraseCount, error) {
	rows, err := repo.db.Query(
		"SELECT user_uuid, count(phrase) FROM phrases GROUP BY user_uuid;",
	)
	if err != nil {
		return nil, err
	}

	defer rows.Close()

	results := []PhraseCount{}
	for rows.Next() {
		row := PhraseCount{}
		if err := rows.Scan(
			&row.UserUUID,
			&row.PhraseCount,
		); err != nil {
			return nil, err
		}
		results = append(results, row)
	}

	return results, nil
}

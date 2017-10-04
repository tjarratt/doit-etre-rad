package db

import (
	"database/sql"
	"fmt"

	cfenv "github.com/cloudfoundry-community/go-cfenv"
	_ "github.com/go-sql-driver/mysql"
	"github.com/mattes/migrate"
	"github.com/mattes/migrate/database/mysql"
	_ "github.com/mattes/migrate/source/file"
)

func OpenConnectionOrPanic(app *cfenv.App) *sql.DB {
	dbService, err := app.Services.WithName("doit-etre-db")
	if err != nil {
		panic(err.Error())
	}

	username, _ := dbService.CredentialString("username")
	password, _ := dbService.CredentialString("password")
	hostname, _ := dbService.CredentialString("hostname")
	port, ok := dbService.CredentialString("port")
	if !ok {
		port = "3306"
	}
	dbName, _ := dbService.CredentialString("name")

	connectionStr := fmt.Sprintf(
		"%s:%s@tcp(%s:%s)/%s",
		username,
		password,
		hostname,
		port,
		dbName,
	)

	db, err := sql.Open("mysql", connectionStr)
	if err != nil {
		panic(err.Error())
	}

	db.SetMaxIdleConns(0)

	runMigrations(db)

	return db
}

func runMigrations(db *sql.DB) {
	driver, err := mysql.WithInstance(db, &mysql.Config{})
	if err != nil {
		panic(err)
	}

	m, err := migrate.NewWithDatabaseInstance(
		"file://migrations",
		"mysql",
		driver,
	)
	if err != nil {
		panic(err)
	}

	err = m.Up()
	if err != nil && err != migrate.ErrNoChange {
		// yes, this api really returns an "error" when there are no changes to make
		// no this is not a great API
		// yes I was quite frustrated when I wrote this comment
		// why do you ask ? ¯\_(ツ)_/¯
		panic(fmt.Sprintf("error during migration: %s", err.Error()))
	}
}

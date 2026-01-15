package main

import (
	"context"
	"log/slog"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/pkg/errors"
)

// ErrCardNotFound is the error which is returned when a card was not found.
var ErrCardNotFound = errors.New("no card found with the given id")

// Database provides functionality to save/retrieve data from the database. It
// is a wrapper around the database.
type Database struct {
	logger *slog.Logger
	conn   *pgxpool.Conn
}

// NewDatabase create a new instance of Database.
func NewDatabase(logger *slog.Logger, conn *pgxpool.Conn) *Database {
	return &Database{
		logger: logger,
		conn:   conn,
	}
}

// Dispose ensures all resources are released. E.g.: the database connection is
// released.
func (db *Database) Dispose() {
	db.conn.Release()
}

// ------------------------------------
//	MUTATING FUNCTIONS
// ------------------------------------

// UpsertCard ensures a card exists in the database with the given cardId and
// data. If an entry already exists with the given cardId, it is overwritten.
//
// The data is a map[string]any. This represents a dynamic object so that the
// backend does not need to know the schema of the frontend.
func (db *Database) UpsertCard(ctx context.Context, cardId string, data map[string]any) error {
	db.logger.Info("adding/updating card", slog.String("cardId", cardId))

	now := time.Now().UTC()

	// add the `id` and `lastModifiedAt` properties to the data. This ensures
	// they are correctly set in the data and the columns to keep things consistent.
	data["id"] = cardId
	data["lastModifiedAt"] = now

	// define the SQL query which will upsert the card in the database.
	const upsertCardQuery = `
		INSERT INTO cards ( id, last_modified_at, data )
		VALUES ( @id, @last_modified_at, @data::jsonb )
		ON CONFLICT (id) DO UPDATE SET 
			last_modified_at = EXCLUDED.last_modified_at,
			data = EXCLUDED.data
    `

	// execute the query with the parameters.
	_, err := db.conn.Exec(ctx, upsertCardQuery, pgx.NamedArgs{
		"id":               cardId,
		"last_modified_at": time.Now().UTC(),
		"data":             data,
	})

	return err
}

// RemoveCard removes the card with the given id from the database.
func (db *Database) RemoveCard(ctx context.Context, cardId string) error {
	db.logger.Info("removing card", slog.String("cardId", cardId))

	// define the quer which will remove the card from the database
	const query = `
		DELETE FROM cards AS card
		WHERE card.id = @id
	`

	// execute the query with the parameters
	_, err := db.conn.Exec(ctx, query, pgx.NamedArgs{
		"id": cardId,
	})

	return err
}

// ------------------------------------
//	QUERY FUNCTIONS
// ------------------------------------

// GetCard retrieves the card with the given cardId from the database. If the
// card does not exist a ErrCardNotFound is returned.
func (db *Database) GetCard(ctx context.Context, cardId string) (map[string]any, error) {
	db.logger.Info("getting card", slog.String("cardId", cardId))

	// define the query which will retrieve the card from the database
	const getCardQuery = `
		SELECT card.id, card.data
		FROM cards AS card
		WHERE card.id = @id`

	// execute the query with the parameters
	rows := db.conn.QueryRow(ctx, getCardQuery, pgx.NamedArgs{"id": cardId})

	var (
		id   string
		data map[string]interface{}
	)

	// read the first row of the received result-set.
	err := rows.Scan(&id, &data)

	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrCardNotFound
		}
		return nil, err
	}

	return data, nil
}

// GetCards retrieves all cards from the database which have been change within
// a given time-window.
func (db *Database) GetCards(ctx context.Context, changesSince time.Time, changesUntil time.Time) ([]map[string]any, error) {
	db.logger.Info("getting cards")

	// define the query which will retrieve the cards from the database
	const getCardsQuery = `
		SELECT
			card.last_modified_at,
			card.data
		FROM cards AS card
		WHERE card.last_modified_at >= @changes_since AND card.last_modified_at <= @changes_until
		ORDER BY card.last_modified_at DESC
	`

	// execute the query with the parameters
	rows, err := db.conn.Query(ctx, getCardsQuery, pgx.NamedArgs{
		"changes_since": changesSince,
		"changes_until": changesUntil,
	})

	if err != nil {
		return nil, err
	}

	// ensure w close the result stream in the end
	defer rows.Close()

	// define a list of results. Each result is a dynamic object so that the
	// backend does not need to know the schema of the frontend.
	var cards = make([]map[string]any, 0)

	// iterate over all the results and ad them to the cards
	for rows.Next() {
		var (
			lastModifiedAt time.Time
			data           map[string]any
		)
		err := rows.Scan(&lastModifiedAt, &data)

		if err != nil {
			return cards, err
		}

		cards = append(cards, data)
	}

	return cards, err
}

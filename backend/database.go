package main

import (
	"context"
	"log/slog"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/pkg/errors"
)

var ErrCardNotFound = errors.New("no card found with the given id")

type DatabaseFactory func(ctx context.Context) (*Database, error)

type Database struct {
	logger *slog.Logger
	conn   *pgxpool.Conn
}

func NewDatabase(logger *slog.Logger, conn *pgxpool.Conn) *Database {
	return &Database{
		logger: logger,
		conn:   conn,
	}
}

func (db *Database) Dispose() {
	db.conn.Release()
}

// ------------------------------------
//	MUTATING FUNCTIONS
// ------------------------------------

func (db *Database) AddOrUpdateCard(ctx context.Context, cardId string, data map[string]any) error {
	db.logger.Info("adding/updating card", slog.String("cardId", cardId))

	now := time.Now().UTC()
	data["id"] = cardId
	data["lastModifiedAt"] = now
	//jsonData, err := json.Marshal(data)
	//if err != nil {
	//	return errors.Wrap(err, "failed to convert card data to json to save in db")
	//}

	const insertCardQuery = `
		INSERT INTO cards ( id, last_modified_at, data )
		VALUES ( @id, @last_modified_at, @data::jsonb )
		ON CONFLICT (id) DO UPDATE SET 
			last_modified_at = EXCLUDED.last_modified_at,
			data = EXCLUDED.data
    `

	_, err := db.conn.Exec(ctx, insertCardQuery, pgx.NamedArgs{
		"id":               cardId,
		"last_modified_at": time.Now().UTC(),
		"data":             data,
	})

	return err
}

func (db *Database) RemoveCard(ctx context.Context, cardId string) error {
	db.logger.Info("removing card", slog.String("cardId", cardId))

	const query = `
		DELETE FROM cards AS card
		WHERE card.id = @id
	`
	_, err := db.conn.Exec(ctx, query, pgx.NamedArgs{
		"id": cardId,
	})

	return err
}

// ------------------------------------
//	QUERY FUNCTIONS
// ------------------------------------

func (db *Database) GetCard(ctx context.Context, cardId string) (map[string]any, error) {
	db.logger.Info("getting card", slog.String("cardId", cardId))

	const getCardQuery = `
		SELECT card.id, card.data
		FROM cards AS card
		WHERE card.id = @id`

	rows := db.conn.QueryRow(ctx, getCardQuery, pgx.NamedArgs{"id": cardId})

	var (
		id   string
		data map[string]interface{}
	)

	err := rows.Scan(&id, &data)

	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrCardNotFound
		}
		return nil, err
	}

	return data, nil
}

func (db *Database) GetCards(ctx context.Context, changesSince time.Time, changesUntil time.Time) ([]map[string]any, error) {
	db.logger.Info("getting cards")

	const getCardsQuery = `
		SELECT
			card.last_modified_at,
			card.data
		FROM cards AS card
		WHERE card.last_modified_at >= @changes_since AND card.last_modified_at <= @changes_until
		ORDER BY card.last_modified_at DESC
	`

	rows, err := db.conn.Query(ctx, getCardsQuery, pgx.NamedArgs{
		"changes_since": changesSince,
		"changes_until": changesUntil,
	})

	if err != nil {
		return nil, err
	}

	var cards = make([]map[string]any, 0)

	defer rows.Close()
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

package main

import (
	"context"
	"log/slog"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
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

func (db *Database) AddOrUpdateCard(ctx context.Context, card CardDetails) error {
	db.logger.Info("adding/updating card",
		slog.String("id", card.Id))

	const insertCardQuery = `
		INSERT INTO cards (
			id,
			text,
			title_color,
			type,
			password,
			red, green, blue,
			tags, note,
			image_front, image_back,
			last_modified_at)
		VALUES (
			@id,
            @text,
            @title_color,
            @type,
            @password,
            @red,
            @green,
            @blue,
            @tags,
            @note,
            @image_front,
            @image_back,
            @last_modified_at)
		ON CONFLICT (id) DO UPDATE SET 
			id = EXCLUDED.id,
			text = EXCLUDED.text,
			title_color = EXCLUDED.title_color,
			type = EXCLUDED.type,
			password = EXCLUDED.password,
			red = EXCLUDED.red,
			green = EXCLUDED.green,
			blue = EXCLUDED.blue,
			tags = EXCLUDED.tags,
			image_front = EXCLUDED.image_front,
			image_back = EXCLUDED.image_back,
			last_modified_at = EXCLUDED.last_modified_at`

	_, err := db.conn.Exec(ctx, insertCardQuery, pgx.NamedArgs{
		"id":               card.Id,
		"text":             card.Text,
		"title_color":      card.TitleColor,
		"type":             card.Type,
		"password":         card.Password,
		"red":              card.Red,
		"green":            card.Green,
		"blue":             card.Blue,
		"tags":             card.Tags,
		"image_front":      card.ImageFront,
		"image_back":       card.ImageBack,
		"last_modified_at": time.Now().UTC(),
	})
	return err
}

func (db *Database) RemoveCard(ctx context.Context, id string) error {
	db.logger.Info("removing card", slog.String("id", id))

	const query = `
		DELETE FROM cards AS card
		WHERE card.id = $id
	`
	_, err := db.conn.Exec(ctx, query, pgx.NamedArgs{"id": id})
	return err
}

// ------------------------------------
//	QUERY FUNCTIONS
// ------------------------------------

func (db *Database) GetCard(ctx context.Context, cardId string) (*CardDetails, error) {
	db.logger.Info("getting card", slog.String("cardId", cardId))

	const getCardQuery = `
		SELECT
			card.id,
			card.text,
			card.title_color,
			card.type,
			card.password,
			card.red,
			card.green,
			card.blue,
			card.tags,
			card.note,
			card.image_front,
			card.image_back,
			card.last_modified_at
		FROM cards AS card
		WHERE card.id = $1`

	rows := db.conn.QueryRow(ctx, getCardQuery, cardId)

	var (
		id             string
		text           string
		titleColor     Color
		tp             string
		password       *string
		red            int
		green          int
		blue           int
		tags           pgtype.Array[string]
		note           *string
		imageFront     []byte
		imageBack      []byte
		lastModifiedAt time.Time
	)

	err := rows.Scan(
		&id, &text, &titleColor, &tp, &password,
		&red, &green, &blue,
		&tags, &note,
		&imageFront, &imageBack,
		&lastModifiedAt)

	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrCardNotFound
		}
		return nil, err
	}

	return &CardDetails{
		Id:             id,
		Text:           text,
		TitleColor:     titleColor,
		Type:           tp,
		Password:       password,
		Red:            red,
		Green:          green,
		Blue:           blue,
		Tags:           tags.Elements,
		Note:           note,
		ImageFront:     imageFront,
		ImageBack:      imageBack,
		LastModifiedAt: lastModifiedAt,
	}, nil
}

func (db *Database) GetCards(ctx context.Context) ([]*CardSummary, error) {
	db.logger.Info("getting cards")

	const getCardsQuery = `
		SELECT
			card.id,
			card.text,
			card.type,
			card.password,
			card.last_modified_at
		FROM cards AS card
		ORDER BY card.last_modified_at DESC
	`

	rows, err := db.conn.Query(ctx, getCardsQuery)

	if err != nil {
		return nil, err
	}

	var cards = make([]*CardSummary, 0)

	defer rows.Close()
	for rows.Next() {
		var (
			id             string
			text           string
			tp             string
			password       *string
			lastModifiedAt time.Time
		)

		err := rows.Scan(
			&id,
			&text,
			&tp,
			&password,
			&lastModifiedAt)

		if err != nil {
			return cards, err
		}

		cards = append(cards, &CardSummary{
			Id:             id,
			Text:           text,
			Type:           tp,
			Password:       password,
			LastModifiedAt: lastModifiedAt,
		})
	}

	return cards, err
}

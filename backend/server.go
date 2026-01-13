package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"time"
)

const cardIdPathParam = "cardId"

// DatabaseFactory is a factory function which creates instances of a database.
type DatabaseFactory func(ctx context.Context) (*Database, error)

type HttpServer struct {
	logger         *slog.Logger
	db             DatabaseFactory
	authMiddleware *AuthMiddleware
}

func NewHttpServer(logger *slog.Logger, db DatabaseFactory, auth *AuthMiddleware) *HttpServer {
	return &HttpServer{
		logger:         logger,
		db:             db,
		authMiddleware: auth,
	}
}

func (serv *HttpServer) RegisterRoutes() {
	serv.handleFunc("/cards/{"+cardIdPathParam+"}",
		serv.authMiddleware.Authenticate(func(res http.ResponseWriter, req *http.Request) error {
			switch req.Method {
			case http.MethodGet:
				return serv.getCard(res, req)
			case http.MethodPut:
				return serv.putCard(res, req)
			case http.MethodDelete:
				return serv.deleteCard(res, req)
			default:
				http.Error(res, "", http.StatusMethodNotAllowed)
				return nil
			}
		}))
	serv.handleFunc("/cards", serv.authMiddleware.Authenticate(func(res http.ResponseWriter, req *http.Request) error {
		switch req.Method {
		case http.MethodGet:
			return serv.getCards(res, req)
		default:
			http.Error(res, "", http.StatusMethodNotAllowed)
		}
		return nil
	}))
	serv.handleFunc("/healthz", func(res http.ResponseWriter, req *http.Request) error {
		res.WriteHeader(200)
		_, _ = res.Write([]byte("OK"))
		return nil
	})
}

func (serv *HttpServer) getCard(res http.ResponseWriter, req *http.Request) error {
	// VALIDATE INPUT
	cardId := req.PathValue(cardIdPathParam)
	if cardId == "" {
		http.NotFound(res, req)
		return nil
	}

	// DO QUERY
	db, err := serv.db(req.Context())
	if err != nil {
		http.Error(res, "failed to get card", http.StatusInternalServerError)
		return fmt.Errorf("failed to connect to the database: %v", err)
	}
	defer db.Dispose()

	score, err := db.GetCard(req.Context(), cardId)
	if err != nil {
		if errors.Is(err, ErrCardNotFound) {
			http.Error(res, "no card found with the given id", http.StatusNotFound)
			return err
		}
		http.Error(res, "failed to get card", http.StatusInternalServerError)
		return fmt.Errorf("failed to lookup card: %v", err)
	}

	// RETURN RESULT
	bs, err := json.Marshal(score)
	if err != nil {
		http.Error(res, "failed to get card", http.StatusInternalServerError)
		return fmt.Errorf("failed to serialize card: %v", err)
	}

	res.Header().Set("Content-Type", "application/json")
	res.WriteHeader(http.StatusOK)
	if _, err = res.Write(bs); err != nil {
		return fmt.Errorf("failed to respond card: %v", err)
	}

	return nil
}

func (serv *HttpServer) putCard(res http.ResponseWriter, req *http.Request) error {
	// VALIDATE INPUT
	cardId := req.PathValue(cardIdPathParam)
	if cardId == "" {
		http.NotFound(res, req)
		return errors.New("no card-id")
	}

	contentType := req.Header.Get("Content-Type")
	if contentType != "application/json" {
		http.Error(res, "content-type not supported", http.StatusUnsupportedMediaType)
		return errors.New("content-type not supported")
	}

	// DO QUERY
	db, err := serv.db(req.Context())
	if err != nil {
		http.Error(res, "failed to save card", http.StatusInternalServerError)
		return fmt.Errorf("failed to connect to the database: %v", err)
	}
	defer db.Dispose()

	var card map[string]any
	dec := json.NewDecoder(req.Body)
	err = dec.Decode(&card)
	if err != nil {
		http.Error(res, "failed to read request body", http.StatusInternalServerError)
		return fmt.Errorf("failed to read request body: %v", err)
	}

	err = db.UpsertCard(req.Context(), cardId, card)
	if err != nil {
		http.Error(res, "failed to save card", http.StatusInternalServerError)
		return fmt.Errorf("failed to save card to the database: %v", err)
	}

	// RETURN RESULT
	res.WriteHeader(http.StatusOK)
	return nil
}

func (serv *HttpServer) deleteCard(res http.ResponseWriter, req *http.Request) error {
	// VALIDATE INPUT
	cardId := req.PathValue(cardIdPathParam)
	if cardId == "" {
		http.NotFound(res, req)
		return nil
	}

	// DO QUERY
	db, err := serv.db(req.Context())
	if err != nil {
		http.Error(res, "failed to get card", http.StatusInternalServerError)
		return fmt.Errorf("failed to connect to the database: %v", err)
	}
	defer db.Dispose()

	err = db.RemoveCard(req.Context(), cardId)
	if err != nil {
		http.Error(res, "failed to delete card", http.StatusInternalServerError)
		return fmt.Errorf("failed to delete card from the database: %v", err)
	}

	// RETURN RESULT
	res.WriteHeader(http.StatusOK)
	return nil
}

func (serv *HttpServer) getCards(res http.ResponseWriter, req *http.Request) error {
	// PARSE REQUEST
	changesSince, err := getChangesSinceParam(req)
	if err != nil {
		http.Error(res, err.Error(), http.StatusBadRequest)
		return err
	}
	changesUntil, err := getChangesUntilParam(req)
	if err != nil {
		http.Error(res, err.Error(), http.StatusBadRequest)
		return err
	}

	// DO QUERY
	db, err := serv.db(req.Context())
	if err != nil {
		http.Error(res, "failed to get cards", http.StatusInternalServerError)
		return fmt.Errorf("failed to connect to the database: %v", err)
	}
	defer db.Dispose()

	cards, err := db.GetCards(req.Context(), changesSince, changesUntil)

	if err != nil {
		http.Error(res, "failed to get cards", http.StatusInternalServerError)
		return fmt.Errorf("failed to query all cards: %v", err)
	}

	// SERIALIZE RESULT
	bs, err := json.Marshal(cards)
	if err != nil {
		http.Error(res, "failed to get cards", http.StatusInternalServerError)
		return fmt.Errorf("failed to serialize cards: %v", err)
	}

	// RETURN RESULT
	res.Header().Set("Content-Type", "application/json")
	res.WriteHeader(http.StatusOK)
	if _, err = res.Write(bs); err != nil {
		return fmt.Errorf("failed respond cards: %v", err)
	}

	return nil
}

func (serv *HttpServer) handleFunc(pattern string, handler func(http.ResponseWriter, *http.Request) error) {
	http.HandleFunc(pattern, cors(LogHandler(serv.logger, handler)))
}

func cors(handler http.HandlerFunc) http.HandlerFunc {
	return func(res http.ResponseWriter, req *http.Request) {
		res.Header().Set("Access-Control-Allow-Origin", "*")
		res.Header().Set("Access-Control-Allow-Headers", "*")
		res.Header().Set("Access-Control-Allow-Methods", "*")
		if req.Method == http.MethodOptions {
			_, _ = res.Write([]byte("OK"))
			return
		}
		handler(res, req)
	}
}

func getChangesSinceParam(req *http.Request) (time.Time, error) {
	s := req.URL.Query().Get("Changes-Since")
	if s == "" {
		return time.Time{}, errors.New("a Changes-Since query param must be provided")
	}

	t, err := time.Parse("20060102T150405", s)
	if err != nil {
		return time.Time{}, errors.New("failed to parse Changes-Since as date-time (YYMMDDThhmmss)")
	}
	if t.UnixNano() == 0 {
		return time.Time{}, errors.New("a Changes-Since query param cannot be empty")
	}
	return t, nil
}

func getChangesUntilParam(req *http.Request) (time.Time, error) {
	s := req.URL.Query().Get("Changes-Until")
	if s == "" {
		return time.Time{}, errors.New("a Changes-Until query param must be provided")
	}

	t, err := time.Parse("20060102T150405", s)
	if err != nil {
		return time.Time{}, errors.New("failed to parse Changes-Until as date-time (YYMMDDThhmmss)")
	}
	if t.UnixNano() == 0 {
		return time.Time{}, errors.New("a Changes-Until query param cannot be empty")
	}
	return t, nil
}

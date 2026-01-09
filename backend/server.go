package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
)

const cardIdPathParam = "cardId"

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

	var card CardDetails
	dec := json.NewDecoder(req.Body)
	err = dec.Decode(&card)
	if err != nil {
		http.Error(res, "failed to read request body", http.StatusInternalServerError)
		return fmt.Errorf("failed to read request body: %v", err)
	}
	card.Id = cardId

	err = db.AddOrUpdateCard(req.Context(), card)
	if err != nil {
		http.Error(res, "failed to save card", http.StatusInternalServerError)
		return fmt.Errorf("failed to save card to the database: %v", err)
	}

	// RETURN RESULT
	res.WriteHeader(http.StatusOK)
	return nil
}

func (serv *HttpServer) getCards(res http.ResponseWriter, req *http.Request) error {
	// DO QUERY
	db, err := serv.db(req.Context())
	if err != nil {
		http.Error(res, "failed to get cards", http.StatusInternalServerError)
		return fmt.Errorf("failed to connect to the database: %v", err)
	}
	defer db.Dispose()

	cards, err := db.GetCards(req.Context())

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

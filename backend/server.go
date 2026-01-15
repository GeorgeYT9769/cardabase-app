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

// HttpServer accepts http requests and serves them a response.
type HttpServer struct {
	// logger logs the requests so that it is possible to monitor the application
	// in production.
	logger *slog.Logger
	// db is a factory function to get a database connection per request.
	db DatabaseFactory
}

func NewHttpServer(logger *slog.Logger, db DatabaseFactory) *HttpServer {
	return &HttpServer{
		logger: logger,
		db:     db,
	}
}

// RegisterRoutes ensures all routes are registered so that the server listens
// to them.
func (serv *HttpServer) RegisterRoutes() {
	// the route http://my-server.com/cards resembles the collection of all cards
	serv.handleFunc("/cards", func(res http.ResponseWriter, req *http.Request) error {
		switch req.Method {
		case http.MethodGet:
			// a GET request on /cards returns all cards in the database. Two
			// query parameters can be provided with this request: Changes-Since
			// and Changes-Until. E.g.: /cards?Changes-Since=20260101T000000&Changes-Until=20260201T140000
			return serv.getCards(res, req)
		default:
			// all other http-methods are not allowed
			http.Error(res, "", http.StatusMethodNotAllowed)
		}
		return nil
	})

	// the route http://my-server.com/cards/my-card-id resembles the collection of all cards
	serv.handleFunc("/cards/{"+cardIdPathParam+"}", func(res http.ResponseWriter, req *http.Request) error {
		switch req.Method {
		case http.MethodGet:
			// a GET request on /cards/my-card-id returns the card with id
			// "my-card-id".
			return serv.getCard(res, req)
		case http.MethodPut:
			// a PUT request on /cards/my-card-id saves the card with id
			// "my-card-id" in the database.
			return serv.putCard(res, req)
		case http.MethodDelete:
			// a DELETE request on /cards/my-card-id removes the card with id
			// "my-card-id" from the database.
			return serv.deleteCard(res, req)
		default:
			// all other http-methods are not allowed
			http.Error(res, "", http.StatusMethodNotAllowed)
			return nil
		}
	})

	// the http://my-server.com/healthz route is a standardized route with
	// which it is possible to see whether the server is healthy and the
	// application running. It only returns ok.
	serv.handleFunc("/healthz", func(res http.ResponseWriter, req *http.Request) error {
		res.WriteHeader(200)
		_, _ = res.Write([]byte("OK"))
		return nil
	})
}

func (serv *HttpServer) getCard(res http.ResponseWriter, req *http.Request) error {
	// get the id of the card from the route
	cardId := req.PathValue(cardIdPathParam)
	if cardId == "" {
		http.NotFound(res, req)
		return nil
	}

	// create a database connection
	db, err := serv.db(req.Context())
	if err != nil {
		http.Error(res, "failed to get card", http.StatusInternalServerError)
		return fmt.Errorf("failed to connect to the database: %v", err)
	}
	defer db.Dispose()

	// get card from the database
	card, err := db.GetCard(req.Context(), cardId)
	if err != nil {
		if errors.Is(err, ErrCardNotFound) {
			http.Error(res, "no card found with the given id", http.StatusNotFound)
			return err
		}
		http.Error(res, "failed to get card", http.StatusInternalServerError)
		return fmt.Errorf("failed to lookup card: %v", err)
	}

	// indicate the client that the content of the response JSON is.
	res.Header().Set("Content-Type", "application/json")
	res.WriteHeader(http.StatusOK)
	// return the card as a JSON object
	if err = json.NewEncoder(res).Encode(card); err != nil {
		return fmt.Errorf("failed to respond card: %v", err)
	}

	return nil
}

func (serv *HttpServer) putCard(res http.ResponseWriter, req *http.Request) error {
	// get the id of the card from the route
	cardId := req.PathValue(cardIdPathParam)
	if cardId == "" {
		http.NotFound(res, req)
		return errors.New("no card-id")
	}

	// ensure that the client is sending JSON
	contentType := req.Header.Get("Content-Type")
	if contentType != "application/json" {
		http.Error(res, "content-type not supported", http.StatusUnsupportedMediaType)
		return errors.New("content-type not supported")
	}

	// read the JSON object from the request body
	var card map[string]any
	dec := json.NewDecoder(req.Body)
	err := dec.Decode(&card)
	if err != nil {
		http.Error(res, "failed to read request body", http.StatusInternalServerError)
		return fmt.Errorf("failed to read request body: %v", err)
	}

	// create a database connection
	db, err := serv.db(req.Context())
	if err != nil {
		http.Error(res, "failed to save card", http.StatusInternalServerError)
		return fmt.Errorf("failed to connect to the database: %v", err)
	}
	defer db.Dispose()

	// save the card in the database
	err = db.UpsertCard(req.Context(), cardId, card)
	if err != nil {
		http.Error(res, "failed to save card", http.StatusInternalServerError)
		return fmt.Errorf("failed to save card to the database: %v", err)
	}

	// nothing to return except that the request has successfully been processed
	res.WriteHeader(http.StatusOK)
	return nil
}

func (serv *HttpServer) deleteCard(res http.ResponseWriter, req *http.Request) error {
	// get the id of the card from the route
	cardId := req.PathValue(cardIdPathParam)
	if cardId == "" {
		http.NotFound(res, req)
		return nil
	}

	// create a connection to the database
	db, err := serv.db(req.Context())
	if err != nil {
		http.Error(res, "failed to get card", http.StatusInternalServerError)
		return fmt.Errorf("failed to connect to the database: %v", err)
	}
	defer db.Dispose()

	// remove the card from the database
	err = db.RemoveCard(req.Context(), cardId)
	if err != nil {
		http.Error(res, "failed to delete card", http.StatusInternalServerError)
		return fmt.Errorf("failed to delete card from the database: %v", err)
	}

	// nothing to return except that the request has successfully been processed
	res.WriteHeader(http.StatusOK)
	return nil
}

func (serv *HttpServer) getCards(res http.ResponseWriter, req *http.Request) error {
	// get the query parameters which indicate which cards are being requested
	// Changes-Since indicates we want all cards which have been changed since that date.
	changesSince, err := getChangesSinceParam(req)
	if err != nil {
		http.Error(res, err.Error(), http.StatusBadRequest)
		return err
	}
	// Changes-Until indicates we want all cards which have been changed until that date.
	changesUntil, err := getChangesUntilParam(req)
	if err != nil {
		http.Error(res, err.Error(), http.StatusBadRequest)
		return err
	}

	// create database connection
	db, err := serv.db(req.Context())
	if err != nil {
		http.Error(res, "failed to get cards", http.StatusInternalServerError)
		return fmt.Errorf("failed to connect to the database: %v", err)
	}
	defer db.Dispose()

	// get the cards from the database
	cards, err := db.GetCards(req.Context(), changesSince, changesUntil)
	if err != nil {
		http.Error(res, "failed to get cards", http.StatusInternalServerError)
		return fmt.Errorf("failed to query all cards: %v", err)
	}

	// indicate the client that the content of the response JSON is.
	res.Header().Set("Content-Type", "application/json")
	res.WriteHeader(http.StatusOK)
	// serialize the cards to JSON for the response
	if err = json.NewEncoder(res).Encode(cards); err != nil {
		return fmt.Errorf("failed respond cards: %v", err)
	}

	return nil
}

// handleFunc is a wrapper around request handlers. It provides default middleware
// like cors and logging.
func (serv *HttpServer) handleFunc(pattern string, handler func(http.ResponseWriter, *http.Request) error) {
	http.HandleFunc(pattern, cors(LogHandler(serv.logger, handler)))
}

// cors is a middleware which adds all origin headers with a wildcard.
//
// This is called CORS functionality. The gist of it is that the server indicates
// which websites are allowed to receive a response. It is a security
// functionality of browsers. If these are not set a website will give CORS issues.
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

// getChangesSinceParam gets the "Changes-Since" query parameter from a request.
//
// If the parameter is not provided it defaults to 2026-01-01.
func getChangesSinceParam(req *http.Request) (time.Time, error) {
	// get the query parameter form the request
	s := req.URL.Query().Get("Changes-Since")
	if s == "" {
		// if it is not provided, return the default value
		return time.Date(2026, 01, 01, 0, 0, 0, 0, time.UTC), nil
	}

	// parse the value as a timestamp
	t, err := time.Parse("20060102T150405", s)
	if err != nil {
		return time.Time{}, errors.New("failed to parse Changes-Since as date-time (YYMMDDThhmmss)")
	}
	if t.UnixNano() == 0 {
		return time.Time{}, errors.New("a Changes-Since query param cannot be empty")
	}
	return t, nil
}

// getChangesUntilParam gets the "Changes-Until" query parameter from a request.
//
// If the parameter is not provided it defaults to the current timestamp.
func getChangesUntilParam(req *http.Request) (time.Time, error) {
	// get the query parameter form the request
	s := req.URL.Query().Get("Changes-Until")
	if s == "" {
		// if it is not provided, return the default value
		return time.Now().UTC(), nil
	}

	// parse the value as a timestamp
	t, err := time.Parse("20060102T150405", s)
	if err != nil {
		return time.Time{}, errors.New("failed to parse Changes-Until as date-time (YYMMDDThhmmss)")
	}
	if t.UnixNano() == 0 {
		return time.Time{}, errors.New("a Changes-Until query param cannot be empty")
	}
	return t, nil
}

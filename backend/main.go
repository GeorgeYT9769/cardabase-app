package main

import (
	"context"
	"database/sql"
	"flag"
	"fmt"
	"log"
	"log/slog"
	"net/http"
	"os"
	"time"

	"github.com/golang-migrate/migrate/v4"
	"github.com/golang-migrate/migrate/v4/database/postgres"
	_ "github.com/golang-migrate/migrate/v4/source/file"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/pkg/errors"
)

// logger is used throughout the application to log requests, responses and other
// data to have insights in how the application works in production.
var logger = slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{Level: slog.LevelDebug}))

// cfg is the global configuration of the server. Contains things like how to
// connect to the database and which identity provider to use.
var cfg = &Config{}

// pgPool is a pool of database connections. Long story short: when a request
// is received, a connection needs to be made to the database. Managing those
// connections, is the task of the pgPool.
var pgPool *pgxpool.Pool

// configPath is the file-path at which the server will search for a
// configuration file. This parameter is passed through the cli.
var configPath string

// keySetProvider is used to get signing keys from. These keys are used to
// verify the authenticity of the users which make the requests. Each key-set
// should be refreshed every 2 hours.
var keySetProvider = NewCachedKeySetProvider(2 * time.Hour)

// main is the entrypoint of the application.
func main() {
	// define which commandline argument exist
	flag.StringVar(&configPath, "config", "config.json", "Specifies the file from which config should be read.")
	flag.Parse()

	// read and parse the configuration file
	var err error
	cfg, err = ConfigFromFile(configPath)
	if err != nil {
		log.Fatalf("failed to get config from file: %v", err)
	}
	logger.Debug("file config", slog.Any("config", cfg.Redacted()))
	logger.Info("validating config")
	if err := cfg.Validate(); err != nil {
		log.Fatalf("config invalid: %v", err)
	}

	logger.Info("starting application")

	// ensure all database tables and columns are up to date
	runDatabaseMigrations()

	// create the database connection pool
	pgPool, err = pgxpool.New(context.Background(), cfg.Db.ConnectionString)
	if err != nil {
		log.Fatalf("failed to obtain db-connection pool: %v", err)
	}

	// start the server
	serveHttp()
}

// runDatabaseMigrations creates a connection to the database and ensures all
// tables are up-to-date.
//
// A relational database like SQL requires a schema which resembles the
// structure of the data which needs to be stored. In our case a table with
// the data of the cards, and id and timestamp at which the card last changed.
func runDatabaseMigrations() {
	logger.Info("running migrations")

	// open the connection to the database
	db, err := sql.Open("postgres", cfg.Db.ConnectionString)
	if err != nil {
		log.Fatalf("failed to open database for migrations: %v", err)
	}

	// initialize the driver
	driver, err := postgres.WithInstance(db, &postgres.Config{})
	if err != nil {
		log.Fatalf("failed to connect to database: %v", err)
	}

	// create run the migrations
	m, err := migrate.NewWithDatabaseInstance("file://db_migrations", "postgres", driver)
	if err != nil {
		log.Fatalf("failed to create migration runner: %v", err)
	}
	if err := m.Up(); err != nil {
		if errors.Is(err, migrate.ErrNoChange) {
			logger.Info("migrations already up-to-date")
			return
		}

		log.Fatalf("failed to run migrations: %v", err)
	}

	logger.Info("migrated successfully")
}

// serveHttp starts the actual server.
func serveHttp() {
	logger.Info("starting http server")

	// create middleware which requires a request to be authenticated
	authMiddleware := NewAuthMiddleware(cfg.Auth.Issuer, cfg.Auth.Audience, keySetProvider)

	// create the server
	scoreServ := NewHttpServer(logger, createScoresDb, authMiddleware)
	scoreServ.RegisterRoutes()

	// start listening for http request
	addr := fmt.Sprintf(":%d", cfg.Http.Port)
	logger.Info("start listening for http requests", slog.String("addr", addr))
	if err := http.ListenAndServe(addr, nil); err != nil {
		logger.Error("failed to serve score scoresIndex",
			slog.Any("error", err))
	}
}

// createScoresDb uses the pgPool to create an instance of the Database. This
// function is used as a factory function which is required for the HttpServer.
func createScoresDb(ctx context.Context) (*Database, error) {
	pgConn, err := pgPool.Acquire(ctx)
	if err != nil {
		return nil, errors.Wrap(err, "failed to create database connection")
	}
	return NewDatabase(logger, pgConn), nil
}

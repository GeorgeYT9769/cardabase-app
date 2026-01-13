package main

import (
	"encoding/json"
	"net/url"
	"os"

	"errors"

	errorspkg "github.com/pkg/errors"
)

// Config describes the configuration of the server.
type Config struct {
	// Db describes the configuration of the database.
	Db DbConfig `json:"db"`
	// Http describes the configuration of the http part of the server.
	Http HttpConfig `json:"http"`
	// Auth describes how the authenticity of requests should be validated.
	Auth AuthConfig `json:"auth"`
}

// DbConfig describes the configuration of the database.
type DbConfig struct {
	// ConnectionString is used to connect to the database. It should contain the
	// host, port, user, password with which a connection can be made.
	//
	// E.g.: `user=postgres password=postgres host=localhost port=5432 dbname=postgres`
	ConnectionString string `json:"connectionString"`
}

// HttpConfig describes the configuration of the http part of the server.
type HttpConfig struct {
	// Port is the tcp-port at which the server should listen.
	Port int `json:"port" default:"5045"`
}

// AuthConfig describes how the authenticity of requests should be validated.
type AuthConfig struct {
	// Issuer is the URL of the server which created the access-token. The issuer
	// in the access-token must match this Issuer.
	Issuer string `json:"issuer"`
	// Audience is a claim (property) in the access-token which defines for which
	// the access-token was created. The audience in the access-token must match
	// this Audience.
	Audience string `json:"audience" default:"cardabase"`
}

func ConfigFromFile(configPath string) (*Config, error) {
	f, err := os.Open(configPath)
	if err != nil {
		return nil, errorspkg.Wrap(err, "failed to open config file")
	}
	defer func(f *os.File) {
		err := f.Close()
		if err != nil {
			panic(err)
		}
	}(f)

	cfg := &Config{}
	decoder := json.NewDecoder(f)
	err = decoder.Decode(cfg)
	if err != nil {
		return nil, errorspkg.Wrap(err, "failed to parse config file")
	}
	return cfg, nil
}

// Validate checks whether the configuration is valid.
func (cfg *Config) Validate() error {
	var errs []error

	if cfg.Http.Port < 80 {
		errs = append(errs, errors.New("cannot listen on a port lower than 80 for listening for http requests"))
	}

	if cfg.Auth.Issuer == "" {
		errs = append(errs, errors.New("no issuer specified in auth configuration"))
	} else if _, err := url.ParseRequestURI(cfg.Auth.Issuer); err != nil {
		errs = append(errs, errorspkg.Wrap(err, "the issuer is not a valid url"))
	}

	if cfg.Auth.Audience == "" {
		errs = append(errs, errors.New("no audience in auth configuration"))
	}

	if cfg.Db.ConnectionString == "" {
		errs = append(errs, errors.New("no db connection-string in db configuration"))
	}

	if len(errs) > 0 {
		return errors.Join(errs...)
	}
	return nil
}

// Redacted creates a copy of the configuration without sensitive information.
func (cfg *Config) Redacted() Config {
	return Config{
		Db: DbConfig{},
		Http: HttpConfig{
			Port: cfg.Http.Port,
		},
		Auth: AuthConfig{
			Issuer:   cfg.Auth.Issuer,
			Audience: cfg.Auth.Audience,
		},
	}
}

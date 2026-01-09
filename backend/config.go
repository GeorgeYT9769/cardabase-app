package main

import (
	"encoding/json"
	"net/url"
	"os"

	"errors"

	errorspkg "github.com/pkg/errors"
)

type Config struct {
	Db   DbConfig   `json:"db"`
	Http HttpConfig `json:"http"`
	Auth AuthConfig `json:"auth"`
}

type DbConfig struct {
	ConnectionString string `json:"connectionString"`
}

type HttpConfig struct {
	Port int `json:"port" default:"5045"`
}

type AuthConfig struct {
	Issuer   string `json:"issuer"`
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

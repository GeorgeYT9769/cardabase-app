package main

import (
	"context"
	"errors"
	"net/http"
	"strings"
	"time"

	"github.com/hashicorp/cap/jwt"
)

type AuthMiddleware struct {
	Issuer         string
	Audience       string
	keySetProvider KeySetProvider
}

func NewAuthMiddleware(issuer string, audience string, keySetProvider KeySetProvider) *AuthMiddleware {
	return &AuthMiddleware{
		Issuer:         issuer,
		Audience:       audience,
		keySetProvider: keySetProvider,
	}
}

func (m *AuthMiddleware) Authenticate(handler func(res http.ResponseWriter, req *http.Request) error) func(res http.ResponseWriter, req *http.Request) error {
	return func(res http.ResponseWriter, req *http.Request) error {
		header := req.Header.Get("Authorization")
		if header == "" {
			http.Error(res, "no authorization header", http.StatusUnauthorized)
			return errors.New("no authorization header")
		}

		split := strings.Split(header, " ")
		scheme := split[0]
		if len(split) != 2 || strings.ToLower(scheme) != "bearer" {
			http.Error(res, "authorization header is malformed. Expected 'Bearer {token}'", http.StatusUnauthorized)
			return errors.New("authorization header is malformed. Expected 'Bearer {token}'")
		}
		token := split[1]

		keyset, err := m.keySetProvider.KeySet(req.Context(), m.Issuer)
		if err != nil {
			return err
		}
		_, err = keyset.VerifySignature(req.Context(), token)
		if err != nil {
			return err
		}

		return handler(res, req)
	}
}

type KeySetProvider interface {
	KeySet(ctx context.Context, issuer string) (jwt.KeySet, error)
}

type CachedKeySetProvider struct {
	cache map[string]cacheEntry
}
type cacheEntry struct {
	fetchDate time.Time
	keySet    jwt.KeySet
}

func (p *CachedKeySetProvider) KeySet(ctx context.Context, issuer string) (jwt.KeySet, error) {
	now := time.Now()
	entry, ok := p.cache[issuer]
	if ok && now.Sub(entry.fetchDate) < 2*time.Hour {
		return entry.keySet, nil
	}

	keySet, err := jwt.NewOIDCDiscoveryKeySet(ctx, issuer, "") // issuer cert can be used from system
	if err != nil {
		return nil, err
	}

	if p.cache == nil {
		p.cache = make(map[string]cacheEntry)
	}
	p.cache[issuer] = cacheEntry{
		fetchDate: now,
		keySet:    keySet,
	}
	return keySet, nil
}

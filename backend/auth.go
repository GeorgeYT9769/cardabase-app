package main

import (
	"context"
	"errors"
	"net/http"
	"strings"
	"time"

	"github.com/hashicorp/cap/jwt"
)

// AuthMiddleware is a middleware which requires a request to be authenticated.
//
// Middleware is a piece of code intercepts a requests and does some operations
// before passing it to the actual handler.
//
// This middleware verifies whether a request is valid according to OIDC. It
// does this by checking whether:
// - an `Authorization` header is present
// - the value of the `Authorization` is a JWT access-token
// - the access-token is issued by the Issuer, and targeted at the Audience.
//
// A JWT exists of 3 parts: `{header}.{payload}.{signature}`. The header defines
// what kind of token it is. In the payload a bunch of claims (properties) exist
// some of which are required by OIDC like `iss` (issuer), `exp` (expiration
// time), `aud` (audience),... The signature is a cryptographic thumbprint of
// the other parts of the token.
type AuthMiddleware struct {
	// Issuer is the URL of the server which created the access-token. The issuer
	// in the access-token must match this Issuer.
	Issuer string
	// Audience is a claim (property) in the access-token which defines for which
	// the access-token was created. The audience in the access-token must match
	// this Audience.
	Audience string
	// keySetProvider is used to get signing keys from. These keys are used to
	// verify the authenticity of the access-token in the requests.
	KeySetProvider KeySetProvider
}

func NewAuthMiddleware(issuer string, audience string, keySetProvider KeySetProvider) *AuthMiddleware {
	return &AuthMiddleware{
		Issuer:         issuer,
		Audience:       audience,
		KeySetProvider: keySetProvider,
	}
}

// Authenticate is the function which is the code which exists between receiving
// the request and the actual handler. It validates a request was mad by an
// authenticated user.
//
// This function accepts a function and returns a function. It is a bit of a
// mindfuck when you first see this, but it is required by the http-router.
func (m *AuthMiddleware) Authenticate(handler func(res http.ResponseWriter, req *http.Request) error) func(res http.ResponseWriter, req *http.Request) error {
	return func(res http.ResponseWriter, req *http.Request) error {
		// get the `Authorization` header from the request
		header := req.Header.Get("Authorization")
		if header == "" {
			http.Error(res, "no authorization header", http.StatusUnauthorized)
			return errors.New("no authorization header")
		}

		// the header should be in the form of "Bearer {token}"
		split := strings.Split(header, " ")
		scheme := split[0]
		if len(split) != 2 || strings.ToLower(scheme) != "bearer" {
			http.Error(res, "authorization header is malformed. Expected 'Bearer {token}'", http.StatusUnauthorized)
			return errors.New("authorization header is malformed. Expected 'Bearer {token}'")
		}
		token := split[1]

		// get a key-set to verify the signature of the token
		keyset, err := m.KeySetProvider.KeySet(req.Context(), m.Issuer)
		if err != nil {
			return err
		}

		// verify the signature
		_, err = keyset.VerifySignature(req.Context(), token)
		if err != nil {
			return err
		}

		// TODO verify the audience

		return handler(res, req)
	}
}

// KeySetProvider is used to get signing keys from. These keys are used to
// verify the authenticity of the users which make the requests.
type KeySetProvider interface {
	// KeySet returns an active key-set for the given issuer.
	KeySet(ctx context.Context, issuer string) (jwt.KeySet, error)
}

// CachedKeySetProvider is a KeySetProvider which caches the key-sets
type CachedKeySetProvider struct {
	// cache is a map in which key-sets are stored linked to the issuer for which
	// they were fetched.
	cache map[string]cacheEntry
	// maxKeySetAge is max age of a key-set in the cache. If this time expires,
	// a new key-set should be fetched from the issuer.
	maxKeySetAge time.Duration
}

func NewCachedKeySetProvider(maxKeySetAge time.Duration) *CachedKeySetProvider {
	return &CachedKeySetProvider{
		cache:        make(map[string]cacheEntry),
		maxKeySetAge: maxKeySetAge,
	}
}

// cacheEntry is an entry in the cache of key-set.
type cacheEntry struct {
	// fetchDate is the time at which the keySet was fetched.
	fetchDate time.Time
	// keySet is the actual keySet which was fetched from the issuer.
	keySet jwt.KeySet
}

func (p *CachedKeySetProvider) KeySet(ctx context.Context, issuer string) (jwt.KeySet, error) {
	now := time.Now()

	// check whether a valid cached keySet exists. If it exists, return it.
	entry, ok := p.cache[issuer]
	if ok && now.Sub(entry.fetchDate) < 2*time.Hour {
		return entry.keySet, nil
	}

	// get the keyset from the issuer
	keySet, err := jwt.NewOIDCDiscoveryKeySet(ctx, issuer, "") // issuer cert can be used from system
	if err != nil {
		return nil, err
	}

	// save the keyset in the cache
	p.cache[issuer] = cacheEntry{
		fetchDate: now,
		keySet:    keySet,
	}
	return keySet, nil
}

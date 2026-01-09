package main

import (
	"context"
	"log/slog"
	"net/http"

	"github.com/google/uuid"
)

const CorrelationIdKey = "correlationId"

func LogHandler(l *slog.Logger, handler func(res http.ResponseWriter, req *http.Request) error) http.HandlerFunc {
	return func(res http.ResponseWriter, req *http.Request) {
		correlationId := req.Header.Get("X-Correlation-ID")
		if correlationId == "" {
			correlationId = uuid.New().String()
		}
		l.Info("handle http request",
			slog.String("method", req.Method),
			slog.String("pattern", req.Pattern),
			slog.String("uri", req.RequestURI),
			slog.String("correlationId", correlationId))

		req = req.WithContext(context.WithValue(req.Context(), CorrelationIdKey, correlationId))
		loggingRes := NewResponseWriter(l, res, correlationId)
		defer loggingRes.Flush()

		loggingRes.Err = handler(loggingRes, req)
	}
}

type ResponseWriter struct {
	logger        *slog.Logger
	response      http.ResponseWriter
	statusCode    int
	correlationId string
	Err           error
}

func NewResponseWriter(
	logger *slog.Logger,
	response http.ResponseWriter,
	correlationId string) *ResponseWriter {
	return &ResponseWriter{
		logger:        logger,
		response:      response,
		correlationId: correlationId,
	}
}

func (w *ResponseWriter) Header() http.Header {
	return w.response.Header()
}
func (w *ResponseWriter) Write(bs []byte) (int, error) {
	return w.response.Write(bs)
}
func (w *ResponseWriter) WriteHeader(statusCode int) {
	w.statusCode = statusCode
	w.response.WriteHeader(statusCode)
}

func (w *ResponseWriter) Flush() {
	switch {
	case w.statusCode >= 500:
		w.logger.Error("http request failed with server error",
			slog.Any("error", w.Err),
			slog.String("correlationId", w.correlationId))
	case w.statusCode >= 400:
		w.logger.Info("http request failed with client error",
			slog.Any("error", w.Err),
			slog.String("correlationId", w.correlationId))
	case w.statusCode == 0:
		w.logger.Warn("unknown http response (response was not http.response)",
			slog.Any("error", w.Err),
			slog.String("correlationId", w.correlationId))
	case w.Err != nil:
		w.logger.Warn("http request succeeded with error",
			slog.Any("error", w.Err),
			slog.String("correlationId", w.correlationId))
	default:
		w.logger.Info("http request succeeded", slog.String("correlationId", w.correlationId))
	}
}

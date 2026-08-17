package wander

import (
	"context"
	"net/http"
	"time"

	"github.com/JeffC25/wander/config"
	"github.com/go-chi/chi"
	"github.com/go-chi/chi/middleware"
)

type Server struct{}

func (s *Server) Run(ctx context.Context, c config.ServerConfig) error {
	r := chi.NewRouter()
	r.Use(middleware.Logger)
	r.Use(middleware.Timeout(30 * time.Second))

	r.Get("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	})

	return nil
}

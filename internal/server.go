package wander

import (
	"context"
	"errors"
	"fmt"
	"log"
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

	server := &http.Server{
		Addr:    fmt.Sprintf(":%d", c.Port),
		Handler: r,
	}

	errC := make(chan error, 1)
	go func() {
		<-ctx.Done()

		shutdownCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()

		errC <- server.Shutdown(shutdownCtx)
	}()

	log.Printf("listening on port %d", c.Port)

	err := server.ListenAndServe()
	if errors.Is(err, http.ErrServerClosed) {
		return nil
	}

	return <-errC
}

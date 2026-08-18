package db

import (
	"context"
	"fmt"

	"github.com/JeffC25/wander/config"
	"github.com/jackc/pgx/v5/pgxpool"
)

func Open(c config.DBConfig) (*pgxpool.Pool, error) {
	pool, err := pgxpool.New(context.Background(), c.URL)
	if err != nil {
		return nil, fmt.Errorf("unable to connect to database: %v", err)
	}

	if err := pool.Ping(context.Background()); err != nil {
		return nil, fmt.Errorf("database ping failed: %v", err)
	}

	return pool, nil
}

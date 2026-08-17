package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/JeffC25/wander/config"
	wander "github.com/JeffC25/wander/internal"
	"golang.org/x/sync/errgroup"
)

var configPath = flag.String("config", "config.yaml", "server config file")

func main() {
	// MARK: Config
	notifyCtx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()
	eg, ctx := errgroup.WithContext(notifyCtx)

	flag.Usage = func() {
		fmt.Fprintf(os.Stderr, "Usage: wander --config <config path>")
	}
	flag.Parse()

	cfg, err := config.GetConfig(*configPath)
	if err != nil {
		log.Fatalf("unable to load config: %v", err)
	}

	// MARK: DB
	// pool, err := pgxpool.New(context.Background(), cfg.Database.URL)
	// if err != nil {
	// 	log.Fatalf("unable to connect to database: %v", err)
	// }
	// defer pool.Close()
	//
	// if err := pool.Ping(context.Background()); err != nil {
	// 	log.Fatalf("database ping failed: %v", err)
	// }

	// MARK: Run server
	s := wander.Server{}
	eg.Go(func() error {
		return s.Run(ctx, cfg.Server)
	})

	// MARK: Handle error group
	err = eg.Wait()
	if err != nil {
		log.Printf("an error occurred: %v", err)
	}
}

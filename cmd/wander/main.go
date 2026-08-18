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
		log.Fatalf("failed to load config: %v", err)
	}

	// MARK: Open database
	// pool, err := db.Open(cfg.Database)
	// if err != nil {
	// 	log.Fatalf("failed to open database connection: %v", err)
	// }
	// defer pool.Close()
	//
	// MARK: Run server
	s := wander.Server{}
	eg.Go(func() error {
		return s.Run(ctx, cfg.Server)
	})

	// MARK: Handle error group
	if err = eg.Wait(); err != nil {
		log.Printf("an error occurred: %v", err)
	}
}

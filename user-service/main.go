package main

import (
	"context"
	"errors"
	"log/slog"
	"net/http"
	"os"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

type Server struct {
	pool   *pgxpool.Pool
	logger *slog.Logger
}

const (
	PORT = ":8000"
)

func main() {
	db := MakePool(context.Background(), os.Getenv("DATABASE_URL"))
	con := Server{db, slog.New(slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{Level: slog.LevelDebug}))}
	defer con.pool.Close()

	mux := http.NewServeMux()
	mux.HandleFunc("POST /users", con.register)
	mux.HandleFunc("POST /login", con.Login)
	srv := &http.Server{
		Addr:         PORT,
		Handler:      mux,
		ReadTimeout:  5 * time.Second,
		WriteTimeout: 5 * time.Second,
		IdleTimeout:  120 * time.Second,
	}

	if err := srv.ListenAndServe(); err != nil {
		con.logger.Error("Server Error", "error", err)
	}
}

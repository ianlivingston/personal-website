package main

import (
	"context"
	"log/slog"
	"os"
	"strings"
	"testing"
)

// TestRegistration is called after registration api request
func TestRegistration(t *testing.T) {

	logger := slog.New(slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{Level: slog.LevelDebug}))
	ctx := context.Background()
	url := os.Getenv("DATABASE_URL")
	logger.Debug("env loaded", "db url", url)
	pool := MakePool(ctx, url)

	t.Cleanup(func() {
		pool.Close()
	})

	var uinfo struct {
		username string
		phash    []byte
	}
	err := pool.QueryRow(ctx, "SELECT username, password_hash FROM users WHERE users.username = $1", "example").Scan(&uinfo.username, &uinfo.phash)
	if err != nil {
		t.Fatal("error upon querying row", "error", err)
	}

	if strings.Split(string(uinfo.phash), "$")[5] == "dogpark" {
		t.Error("password isn't hashed")
	}
}

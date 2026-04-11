package main

import (
	"log/slog"
	"net/http"
	"time"
)

const PORT = ":8080"

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("POST /users", register)
	srv := &http.Server{
		Addr:         PORT,
		Handler:      mux,
		ReadTimeout:  5 * time.Second,
		WriteTimeout: 5 * time.Second,
		IdleTimeout:  120 * time.Second,
	}

	if err := srv.ListenAndServe(); err != nil {
		slog.Error("Server Error", err)
	}
}

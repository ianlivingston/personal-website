package main

import (
	"crypto/rand"
	"encoding/json"
	"io"
	"net/http"
)

type user struct {
	usr string
	pwd string
}

func register(w http.ResponseWriter, r *http.Request) {
	var newUser user
	if err := readJSON(r.Body, &newUser); err != nil {
		w.WriteHeader(http.StatusBadRequest)
		return
	}

}

func readJSON[T any](data io.Reader, ptr *T) error {
	if err := json.NewDecoder(data).Decode(ptr); err != nil {
		return err
	}
	return nil
}

func generateSalt(lengthInBytes int) ([]byte, error) {
	salt := make([]byte, lengthInBytes)

	if _, err := rand.Read(salt); err != nil {
		return salt, err
	}

	return salt, nil
}

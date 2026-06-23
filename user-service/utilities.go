package main

import (
	"crypto/rand"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"net/http"

	"golang.org/x/crypto/argon2"
)

func readJSON[T any](data io.Reader, ptr *T) error {
	err := json.NewDecoder(data).Decode(ptr)
	return err
}

func (s *Server) jsonResponse(w http.ResponseWriter, status int, message string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	err := json.NewEncoder(w).Encode(message)
	if err != nil {
		s.logger.Error("failed to encode json response", "Error:", err)
	}
}

func createPasswordHash(password string) []byte {

	const (
		m          = 1024 * 64
		t          = 1
		p          = 2
		saltLength = 16
		keyLength  = 32
	)

	salt, _ := createSalt(saltLength)
	hash := argon2.IDKey([]byte(password), salt, t, m, p, keyLength)
	b64Password := base64.StdEncoding.EncodeToString(hash)
	passwordHashString := fmt.Sprintf("$argon2id$v=19$m=%d,t=%d,p=%d$%s$%s", m, t, p, salt, b64Password)
	return []byte(passwordHashString)
}

func createSalt(lengthInBytes int) ([]byte, error) {
	salt := make([]byte, lengthInBytes)
	_, err := rand.Read(salt)
	return salt, err
}

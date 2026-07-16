package main

import (
	"crypto/subtle"
	"encoding/base64"
	"errors"
	"fmt"
	"net/http"
	"strings"

	"github.com/jackc/pgx/v5"
	"golang.org/x/crypto/argon2"
)

func (s *Server) Login(w http.ResponseWriter, r *http.Request) {
	var LoginRequest userCredentials

	err := readJSON(r.Body, &LoginRequest)
	if err != nil {
		s.jsonResponse(w, http.StatusBadRequest, "invalid format for user credentials")
		return
	}

	var hashedPassword []byte
	ctx := r.Context()
	pgErr := s.pool.QueryRow(ctx, "SELECT password_hash FROM users WHERE username = $1", LoginRequest.Username).Scan(&hashedPassword)
	if errors.Is(pgErr, pgx.ErrNoRows) {
		s.logger.Debug("username failed", "username", LoginRequest.Username)
		s.jsonResponse(w, http.StatusUnauthorized, "invalid username or password")
		return
	} else if pgErr != nil {
		w.WriteHeader(http.StatusInternalServerError)
	}

	ok, err := verifyPassword(LoginRequest.Password, string(hashedPassword))

	if err != nil {
		s.logger.Error("error verifying password", "username", LoginRequest.Username, "error", err)
	} else if ok {
		s.logger.Info("user successfully logged in", "username", LoginRequest.Username)
		s.jsonResponse(w, http.StatusOK, "user successfully logged in")
	} else {
		s.logger.Debug("password failed", "username", LoginRequest.Username)
		s.jsonResponse(w, http.StatusUnauthorized, "invalid username or password")
	}
}

// Argon2ID
func verifyPassword(password string, hashedPassword string) (bool, error) {
	hashParts := strings.Split(hashedPassword, "$")
	if len(hashParts) != 6 {
		return false, fmt.Errorf("invalid hash format; length = %v; pwd = %s", len(hashParts), hashedPassword)
	}

	var m, t uint32
	var p uint8

	fmt.Sscanf(hashParts[3], "m=%d,t=%d,p=%d", &m, &t, &p)
	salt, _ := base64.RawStdEncoding.DecodeString(hashParts[4])
	passwordInDB, _ := base64.RawStdEncoding.DecodeString(hashParts[5])
	userPassword := argon2.IDKey([]byte(password), salt, t, m, p, keyLength)
	return subtle.ConstantTimeCompare(passwordInDB, userPassword) == 1, nil
}

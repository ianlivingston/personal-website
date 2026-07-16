package main

import (
	"encoding/json"
	"errors"
	"net/http"

	"github.com/jackc/pgx/v5/pgconn"
)

const PostgresUniqueError string = "23505"

type userCredentials struct {
	Username string `json:"username"`
	Password string `json:"password"`
}

func (s *Server) register(w http.ResponseWriter, r *http.Request) {
	var newUser userCredentials

	err := json.NewDecoder(r.Body).Decode(&newUser)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	ctx := r.Context()
	ph := createPasswordHash(newUser.Password)
	_, err = s.pool.Exec(ctx, "INSERT INTO users (username, password_hash) VALUES ($1, $2)", newUser.Username, ph)
	if err != nil {
		if pgErr, ok := errors.AsType[*pgconn.PgError](err); ok {
			switch pgErr.Code {
			case PostgresUniqueError:
				s.logger.Error("user already exists: ", "username", newUser.Username)
				s.jsonResponse(w, http.StatusConflict, "user already exists")
				return
			}
		}

		s.logger.Error("DB failed adding user", "username", newUser.Username, "error", err)
		s.jsonResponse(w, http.StatusInternalServerError, "DB failed adding user: "+err.Error())
		return
	}

	s.jsonResponse(w, http.StatusCreated, "user registered successfully")
}

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

func (con *Connections) register(w http.ResponseWriter, r *http.Request) {
	var newUser userCredentials

	err := json.NewDecoder(r.Body).Decode(&newUser)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	ctx := r.Context()
	_, err = con.pool.Exec(ctx, "INSERT INTO users (username, password_hash) VALUES ($1, $2)", newUser.Username, createPasswordHash(newUser.Password))
	if err != nil {
		if pgErr, ok := errors.AsType[*pgconn.PgError](err); ok {
			switch pgErr.Code {
			case PostgresUniqueError:
				con.logger.Error("user already exists: ", "username", newUser.Username)
				jsonResponse(w, http.StatusConflict, "user already exists")
				return
			}
		}

		con.logger.Error("DB failed adding user", "username", newUser.Username, "error", err)
		jsonResponse(w, http.StatusInternalServerError, "DB failed adding user: "+err.Error())
		return
	}

	jsonResponse(w, http.StatusCreated, "user registered successfully")
}

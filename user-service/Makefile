test-reg:
	docker compose up -d
	sleep 1
	hurl register.hurl
	DATABASE_URL="postgres://app:pass@localhost:5432/test?sslmode=disable" go test -v ./...
	docker compose down --rmi local
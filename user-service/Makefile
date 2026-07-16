test-reg:
	docker compose up -d
	sleep 1
	hurl api-requests/register.hurl
	DATABASE_URL="postgres://app:pass@localhost:5432/test?sslmode=disable" go test -v ./...
	docker compose down --rmi local

test:
	docker compose up -d
	sleep 1
	hurl api-requests/register.hurl
	DATABASE_URL="postgres://app:pass@localhost:5432/test?sslmode=disable" go test -v ./...
	sleep 1
	hurl api-requests/login-bad-username.hurl
	hurl api-requests/login-bad-password.hurl
	hurl api-requests/login-valid.hurl
	docker compose down --rmi local

debug:
	docker compose up -d
	sleep 1
	hurl api-requests/register.hurl
	DATABASE_URL="postgres://app:pass@localhost:5432/test?sslmode=disable" go test -v ./...
	sleep 1
	hurl -v api-requests/login-bad-username.hurl
	hurl -v api-requests/login-bad-password.hurl
	hurl -v api-requests/login-valid.hurl

clean:
	docker compose down --rmi local
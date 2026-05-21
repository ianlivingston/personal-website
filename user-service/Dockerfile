#Stage 1
FROM golang:1.26 AS build
RUN useradd api
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY *.go ./
RUN go build -o app

#Stage 2
FROM gcr.io/distroless/static-debian12 AS run
WORKDIR /app
EXPOSE 8000
COPY --from=build /etc/passwd /etc/passwd
USER api
COPY --from=build app .
CMD ["./app"]
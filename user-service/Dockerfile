#Stage 1
FROM golang:1.26 AS build
WORKDIR /build
COPY go.mod go.sum ./
RUN go mod download
COPY *.go ./
RUN CGO_ENABLED=0 GOOS=linux go build -o app

#Stage 2
FROM gcr.io/distroless/static-debian13:nonroot AS run
WORKDIR /
EXPOSE 8000
COPY --from=build /build/app /
CMD ["/app"]
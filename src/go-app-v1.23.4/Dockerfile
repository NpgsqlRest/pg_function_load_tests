FROM golang:1.23-alpine AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY main.go ./
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o main .

FROM alpine:3.20
COPY --from=builder /app/main /main
EXPOSE 5200
CMD ["/main"]

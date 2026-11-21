FROM golang:1.27-alpine AS builder

WORKDIR /app
COPY go.mod ./
COPY main.go ./
RUN go mod tidy && CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o main .

FROM alpine:3.24
COPY --from=builder /app/main /main
EXPOSE 5201
CMD ["/main"]

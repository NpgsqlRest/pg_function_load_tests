FROM rust:1.97-slim AS builder
WORKDIR /usr/src/app
COPY Cargo.toml Cargo.lock ./
COPY src ./src
RUN cargo build --release

FROM debian:trixie-slim
COPY --from=builder /usr/src/app/target/release/axum-postgres-app /usr/local/bin/
EXPOSE 5301
CMD ["axum-postgres-app"]

FROM rust:1.91-slim AS builder
WORKDIR /usr/src/app
COPY Cargo.toml Cargo.lock ./
COPY src ./src
RUN cargo build --release

FROM debian:bookworm-slim
COPY --from=builder /usr/src/app/target/release/rust-postgres-app /usr/local/bin/
EXPOSE 5300
CMD ["rust-postgres-app"]

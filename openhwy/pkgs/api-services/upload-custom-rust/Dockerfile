FROM rust:1.75 as builder

WORKDIR /app

COPY Cargo.toml Cargo.lock ./
COPY src ./src

RUN cargo build --release

FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/target/release/upload_service /usr/local/bin/upload_service

RUN mkdir -p /uploads/images /uploads/documents /uploads/thumbnails /uploads/other

WORKDIR /app

EXPOSE 8006

CMD ["upload_service"]

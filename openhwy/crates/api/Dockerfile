FROM rust:1.81-bullseye as builder
WORKDIR /usr/src/api
COPY ../../api/Cargo.toml ../../api/Cargo.lock ./
RUN cargo fetch
COPY ../../api .
RUN cargo build --release

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*
COPY --from=builder /usr/src/api/target/release/hwy-tms-api /usr/local/bin/
WORKDIR /usr/local/bin
ENV RUST_LOG=hwy_tms_api=info
CMD ["hwy-tms-api"]

FROM alpine:latest
RUN apk add --no-cache curl unzip && \
    curl -L https://github.com/duckdb/duckdb/releases/latest/download/duckdb_cli-linux-amd64.zip -o duckdb.zip && \
    unzip duckdb.zip && \
    mv duckdb /usr/local/bin/ && \
    rm duckdb.zip
WORKDIR /data
CMD ["duckdb", "/data/database.duckdb"]

# scripts/build.sh
#!/bin/bash

set -e

echo "Building Payment Service..."

# Set build variables
BUILD_TIME=$(date -u '+%Y-%m-%d_%H:%M:%S')
GIT_COMMIT=$(git rev-parse --short HEAD)
VERSION=${VERSION:-"1.0.0"}

# Build flags
LDFLAGS="-X main.version=${VERSION} -X main.buildTime=${BUILD_TIME} -X main.gitCommit=${GIT_COMMIT}"

# Clean previous builds
echo "Cleaning previous builds..."
rm -f payment-service

# Download dependencies
echo "Downloading dependencies..."
go mod download
go mod tidy

# Run tests
echo "Running tests..."
go test -v ./...

# Build application
echo "Building application..."
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags "${LDFLAGS}" \
    -o payment-service \
    ./cmd/server

echo "Build completed successfully!"
echo "Binary: payment-service"
echo "Version: ${VERSION}"
echo "Build Time: ${BUILD_TIME}"
echo "Git Commit: ${GIT_COMMIT}"

#!/bin/bash
# Build script for Conversation Intelligence Agent

set -e

echo "Building Conversation Intelligence Agent..."

# Build in release mode
cargo build --release

echo "✓ Build complete!"
echo ""
echo "Binary location: target/release/conversation-intelligence"
echo ""
echo "To run:"
echo "  cargo run --release"
echo "or"
echo "  ./target/release/conversation-intelligence"
echo ""
echo "Make sure SurrealDB is running first!"

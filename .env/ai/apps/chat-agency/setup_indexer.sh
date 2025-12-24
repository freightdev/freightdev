#!/bin/bash
# Setup script for conversation indexer

echo "🚀 Setting up Conversation Indexer"
echo "=================================="

# Check for Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is required but not installed"
    exit 1
fi

# Check for pip
if ! command -v pip3 &> /dev/null; then
    echo "❌ pip3 is required but not installed"
    exit 1
fi

# Install DuckDB if not already installed
echo "📦 Installing dependencies..."
pip3 install --user duckdb 2>&1 | grep -v "already satisfied" || true

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Index your exports:"
echo "   python3 conversation_indexer.py ~/store/private/exports"
echo ""
echo "2. Query your conversations:"
echo "   python3 query_conversations.py search 'python'"
echo "   python3 query_conversations.py topics"
echo "   python3 query_conversations.py timeline"
echo ""
echo "3. Export to CSV for further analysis:"
echo "   python3 query_conversations.py export my_conversations.csv"

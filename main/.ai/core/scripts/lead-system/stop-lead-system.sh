#!/bin/bash
# Stop all lead generation services

echo "🛑 Stopping Lead Generation System"
echo "===================================="
echo ""

systemctl --user stop lead-manager.service 2>/dev/null || true
echo "✓ Lead Manager stopped"

systemctl --user stop lead-analyzer.service 2>/dev/null || true
echo "✓ Lead Analyzer stopped"

systemctl --user stop lead-scraper.service 2>/dev/null || true
echo "✓ Lead Scraper stopped"

systemctl --user stop llamacpp.service 2>/dev/null || true
echo "✓ LLM Server stopped"

systemctl --user stop surrealdb.service 2>/dev/null || true
echo "✓ SurrealDB stopped"

echo ""
echo "✅ All services stopped"

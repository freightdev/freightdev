# Migration to SurrealDB - Status

**Date:** 2025-11-20
**Status:** 🚧 In Progress

## ✅ Completed

1. Updated docker-compose.yml - PostgreSQL → SurrealDB
2. Updated .env with SurrealDB configuration
3. Removed n8n (not needed for v0.1, can add back later)

## 🚧 TODO

1. Update lead-engine/package.json - Remove `pg`, add `surrealdb.js`
2. Update api-server/package.json - Remove `pg`, add `surrealdb.js`
3. Create db wrapper for SurrealDB in both services
4. Update database queries to SurrealQL syntax
5. Test docker-compose up
6. Verify lead scraping works
7. Verify API endpoints work

## 📝 Notes

- SurrealDB uses different query syntax than PostgreSQL
- Need to update all SQL queries to SurrealQL
- Tables become "records" in SurrealDB
- Relations work differently (graph-based)

## 🎯 Quick Start Once Done

```bash
cd ~/freightdev/openhwy/.ai/lead-agency
docker-compose up -d
docker-compose logs -f lead-engine
```

Should see: "Lead Engine started, connected to SurrealDB"
